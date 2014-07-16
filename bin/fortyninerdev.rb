###################################################################################################
###################################################################################################
#       Copyright(c) 2007 David Milligan.
#
#       This program is free software: you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation, either version 3 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program.  If not, see <http://www.gnu.org/licenses/>.
###################################################################################################
###################################################################################################

###################################################################################################
##   Module Name    :-  MFunction
##   Description    :-  This module contains methods called from the command line.
###################################################################################################
module MFunction


    ###############################################################################################
    ##   Method Name    :-  filter_logfile
    ##   Description    :-  This method filters a logfile by a given status.
    ##   Parameters     :-  aStatus -  The status of log messages to  filter by.
    ##   Return Value   :-  None.
    ###############################################################################################
    def filter_logfile(aFileName, *aStatus)

        debug(ENTRY, "filter_logfile")
        filteredLines = []
        contents = IO.readlines(aFileName)
        contents.each_with_index do |line, idx|

            if (line =~ /(#{aStatus.join('|')})/)
                regexPath = "#{" " * 260} file:#{aFileName} " + "line:#{idx + 1}"
                filteredLines << line.strip + regexPath.gsub!(/\\/, "/")
            end
        end

        if (filteredLines.size > 0)
            puts filteredLines
        else
            puts "No entries matching #{aStatus.join('|')}"
        end

        debug(EXIT, "filter_logfile")

    end  #  filter_logfile

    ###############################################################################################
    ##   Method Name    :-  load_run_javascript
    ##   Description    :-  This method opens javascript and output html page.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def load_run_javascript()

        debug(ENTRY, "load_run_javascript")

        open_file($path[:JAVASCRIPT_SRC])
        open_file($path[:JAVASCRIPT_DISPLAY])

        debug(EXIT, "load_run_javascript")

    end  #  load_run_javascript

    ###############################################################################################
    ##   Method Name    :-  show_logs
    ##   Description    :-  This method displays a list of logfiles so that you can pick one to
    ##                      tail.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def show_logs

        debug(ENTRY, "show_logs")

        puts "Select logfile"
        LOGFILES.each_with_index do |log, idx|
            if (File.exist?(log))
                puts "#{idx}). #{log} #{" " * 260} file:#{log}" +
                     " line:#{1}"
            else
                puts "#{idx}[Not Present]). #{log} #{" " * 260} file:#{log}" +
                     " line:#{1}"
            end
        end

        debug(EXIT, "show_logs")

    end  #  show_logs

    ###############################################################################################
    ##   Method Name    :-  query_ruby_forum
    ##   Description    :-  This method querys the ruby forum for keywords.
    ##   Parameters     :-  aKeyWords - words to search the forum for.
    ##   Return Value   :-  None.
    ###############################################################################################
    def query_ruby_forum(*aKeyWords)

        debug(ENTRY, "query_ruby_forum")

        queryStr = '%2B'
        aKeyWords.map! { |w| w.strip }
        aKeyWords.each_with_index do |w, idx|
            queryStr << ((idx < (aKeyWords.size - 1)) ? w + '+%2B' : w)
        end

        searchPattern = "search?query=#{queryStr}&forums%5B%5D=4&max_age=-"
        searchPattern = nil if (aKeyWords.size == 0)
        url = "http://www.ruby-forum.com/#{searchPattern}"

        ie = WIN32OLE.new('InternetExplorer.Application')
        ie.visible = true
        ie.navigate(url)

        debug(EXIT, "query_ruby_forum")

    end  #  query_ruby_forum

    ###############################################################################################
    ##   Method Name    :-  prospect_for
    ##   Description    :-  Presents a list of directories to search, restricted by extension.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def prospect_for

        debug(ENTRY, "prospect_for")

         #  Trying out using proc.
        projectNames = PROJECTS.keys
        sortByPreferredIndex = proc do |a,b|
            aIdx = PROJECTS[a][PREFERRED_IDX] || 99999999
            bIdx = PROJECTS[b][PREFERRED_IDX] || 99999999
            aIdx <=> bIdx
        end
        names = projectNames.sort(&sortByPreferredIndex)
        names.map! { |n| n.to_s }

        names.each_with_index do |name, idx|

            # match the symbol to the string representation
            sym = projectNames.find { |n| n.to_s == name }

            #  Get the extensions for each project.
            exts = PROJECTS[sym][FILE_EXT_IDX]
            if (names.size > 0)
                msg = "#{idx + 1}) #{name}, #{exts}"

                puts msg
            end
        end

        aMsg = "select project directory to load(1..#{names.size})"
        prompt =  "\n#{aMsg} 'x|X' to exit..."
        print prompt
        index = $stdin.gets
        index.strip!

        raise ForcedExit.new(index) if ((index.empty?)  || (index =~ /^(x|X)$/))

        if (!/(\d|x|X)/.match(index))
            raise ForcedExit.new("Invalid Input #{index}")
        end
        index = index.to_i - 1
        if (index >= names.size)

            pause_until_keystroke("Invalid Index[#{index}]")
        else

            selection = names[index]
            #  match the string back to the symbol
            findProjectNames = proc { |n| n.to_s == selection }
            projectName = projectNames.find(&findProjectNames)
            if (FileTest.exist?(PROJECTS[projectName][HOME_DIR_IDX]))

                change_config_current_search_file(projectName);
            else

                pause_until_keystroke("#{projectName} at "\
                            "'#{PROJECTS[projectName][HOME_DIR_IDX]}' " +
                             "does not exist.")
            end
        end

        debug(EXIT, "prospect_for")

    end  #  prospect_for

    ###############################################################################################
    ##   Method Name    :-  dig_for
    ##   Description    :-  This method retrieves a list of project files and searches for a
    ##                      pattern in filenames.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def dig_for(aIgnoreCase, aExactMatch, *aKeywords)

        debug(ENTRY, "dig_for")

        cache_filenames()

        results = Array.new
        searchParam = '.*'

        if (aKeywords.size > 0)
            searchParam = aKeywords
        end

        caseSensitivity = ($options[:CASE_SENSITIVE][OPTION_VALUE_IDX]) ? 0 : Regexp::IGNORECASE
        caseSensitivity = (aIgnoreCase) ? Regexp::IGNORECASE : caseSensitivity

        $fileList.each do |file|

            searchFullPath = $options[:SEARCH_FULL_PATHS][OPTION_VALUE_IDX]
            uri = (searchFullPath == true) ? file : File.basename(file)
            found = true
            searchParam.each do |p|

                regEx = (aExactMatch) ? "\\b#{p}\\b" : "#{p}"
                pattern = Regexp.new(regEx, caseSensitivity)

                if (pattern.match(uri))
                    found &= true
                else
                    found = false
                    break
                end
            end
            results << file if (found)

        end

        results.sort! { |a,b| File.basename(a).downcase <=> File.basename(b).downcase }

        if (results.size > 0)
            display_file_list(results)
        else
            pause_until_keystroke("No files matching /#{searchParam}/")
        end

        debug(EXIT, "dig_for")

    end  #  dig_for

    ###############################################################################################
    ##   Method Name    :-  quarry_for
    ##   Description    :-  This method reloads the filelist for the current search directory.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def quarry_for(aPauseAfter = true)

        debug(ENTRY, 'quarry_for')

        $fileList = Array.new

        Find.find($SEARCH_HOME) do |path|

            if (path =~ /#{$SEARCH_EXTENSIONS}$/)

                next if (FileTest.file?(path) == false)

                unless (($EXCLUDESEARCHDIRS != nil) && (path =~ /#{$EXCLUDESEARCHDIRS}/))

                    $fileList << path
                end
            end
        end

        indexFile = File.new($PROJECT_INDEX_FILENAME, "w+")
        indexFile.puts($fileList.join("\n"))
        indexFile.close
        pause_until_keystroke("QUARRY #{$fileList.size} files found.") if (aPauseAfter)

        debug(EXIT, "quarry_for")

    end  #  quarry_for

    ###############################################################################################
    ##   Method Name    :-  show_help
    ##   Description    :-  This method displays the help_out blurb on the console.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def show_help

        debug(ENTRY, "show_help")

        pause_until_keystroke("Help not implemented")

        debug(EXIT, "show_help")

    end  #  show_help

    ###############################################################################################
    ##   Method Name    :-  create_method_template
    ##   Description    :-  This method creates a method template.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def create_method_template(filename, lineNumber, *args)

        debug(ENTRY, 'create_method_template')

        methodName = args[0]
        description = args[1]
        parameters = args - [methodName, description]

        strExpansion = [methodName, wrap_description(description), wrap_parameters(parameters),
                         methodName, parameters.join(', '), methodName, methodName, methodName]

        template = "#{METHOD_TEMPLATE}" % strExpansion.collect!{|x| x.to_s}

        add_template_to_file(template, filename, (lineNumber - 1))

        debug(EXIT, 'create_method_template')

    end  #  create_method_template

    ###############################################################################################
    ##   Method Name    :-  create_class_template
    ##   Description    :-  This method creates a template for a new class.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def create_class_template(filename, lineNumber, *args)

        debug(ENTRY, 'create_class_template')

        nameAndDescription = 0; file = 1; line = 2;

        className =  args[0]
        description = args[1]

        strExpansion = [className, wrap_description(description), className, className]

        template = "#{CLASS_TEMPLATE}" % strExpansion.collect!{|x| x.to_s}

        add_template_to_file(template, filename, lineNumber - 1)

        debug(EXIT, 'create_class_template')

    end  #  create_class_template

    ###############################################################################################
    ##   Method Name    :-  create_module_template
    ##   Description    :-  This method creates a template for a new module.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def create_module_template(filename, lineNumber, *args)

        debug(ENTRY, 'create_module_template')

        moduleName =  args[0]
        description = args[1]

        strExpansion = [moduleName, wrap_description(description), moduleName, moduleName]

        template = "#{MODULE_TEMPLATE}" % strExpansion.collect!{|x| x.to_s}

        add_template_to_file(template, filename, lineNumber - 1)

        debug(EXIT, 'create_module_template')

    end  #  create_module_template

    ###############################################################################################
    ##   Method Name    :-  find_method
    ##   Description    :-  This method finds a method in a directory tree.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def find_method(aKeyWord)

        debug(ENTRY, 'find_method')

        cache_filenames()
        result = $fileList.find { |filename| find_ruby_method_in_file(filename, aKeyWord) }

        puts message_out("<#{aKeyWord}> method not found") if (!result)

        debug(EXIT, 'find_method')

    end  #  find_method
    
    ###############################################################################################
    ##   Method Name    :-  find_javascript_method
    ##   Description    :-  This method finds a method in a directory tree.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def find_javascript_method(aKeyWord)

        debug(ENTRY, 'find_method')

        cache_filenames()
        result = $fileList.find { |filename| find_javascript_method_in_file(filename, aKeyWord) }

        puts message_out("<#{aKeyWord}> method not found") if (!result)

        debug(EXIT, 'find_method')

    end  #  find_method    

    ###############################################################################################
    ##   Method Name    :-  find_method_in_current_dir
    ##   Description    :-  This method finds a method in the current directory.
    ##   Parameters     :-  aDirectory - Thye directory to search.
    ##   Return Value   :-  None.
    ###############################################################################################
    def find_method_in_current_dir(aKeyWord, aDirectory)

        debug(ENTRY, "find_method_in_current_dir")

        $fileList = []
        Find.find(aDirectory) do |path|

            next if (FileTest.file?(path) == false)
            $fileList << path
        end
        result = $fileList.find { |filename| find_ruby_method_in_file(filename, aKeyWord) }

        puts message_out("<#{aKeyWord}> method not found in #{aDirectory}") if (!result)

        debug(EXIT, "find_method_in_current_dir")

    end  #  find_method_in_current_dir

    ###############################################################################################
    ##   Method Name    :-  drill_down
    ##   Description    :-  This method prepares a list of files for processing a search for a
    ##                      pattern.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def drill_down(aMaxResults, aIgnoreCase, aExactMatch, *args)

        debug(ENTRY, 'drill_down')

        cache_filenames()
        pattern = nil

        caseSensitivity = ($options[:CASE_SENSITIVE][OPTION_VALUE_IDX]) ? nil : Regexp::IGNORECASE
        caseSensitivity = (aIgnoreCase) ? Regexp::IGNORECASE : caseSensitivity

        regex = (aExactMatch) ? "\\b#{args}\\b" : "#{args}"
        pattern = Regexp.new(regex, caseSensitivity)

        results = Hash.new

        $fileList.each do |filename|

            break if (aMaxResults <= 0)
            maxResults = find_pattern_in_file(filename, pattern, results, aMaxResults)

        end

        print_drill_results(results, pattern.source)

        debug(EXIT, 'drill_down')

    end  #  drill_down

    ###############################################################################################
    ##   Method Name    :-  clear_log_file
    ##   Description    :-  This method clear the given logfile.
    ##   Parameters     :-  aFilePath - a path to a file.
    ##   Return Value   :-  None.
    ###############################################################################################
    def clear_log_file(aIdx)

        debug(ENTRY, 'clear_log_file')

        raise ForcedExit.new("No logfile at index[aIdx]") if (!LOGFILES[aIdx])

        logFile = File.new(LOGFILES[aIdx], File::WRONLY|File::TRUNC|File::CREAT)
        logFile.close

        debug(INFO, "#{LOGFILES[aIdx]} cleared")

        debug(EXIT, 'clear_log_file.')

    end  #  clear_log_file

    ###############################################################################################
    ##   Method Name    :-  tail_log_file
    ##   Description    :-  This method tails a given logfile, and adds a link to the last logfile
    ##                      that was backed up.
    ##   Parameters     :-  aFilePath - a path to a file.
    ##   Return Value   :-  None.
    ###############################################################################################
    def tail_log_file(aIdx)

        debug(ENTRY, 'tail_log_file')

        raise ForcedExit.new("No logfile at index[#{aIdx}]") if (!LOGFILES[aIdx])

        log = File.open(LOGFILES[aIdx], File::RDONLY)
        tailsize = ($options[:LOG_TAIL_SIZE][OPTION_VALUE_IDX] * 1024)
        logSize = log.stat.size
        offset = (tailsize > logSize) ? logSize : tailsize
        log.seek((-1 * offset), IO::SEEK_END)
        puts link_to_previous_log(LOGFILES[aIdx])
        puts log.readlines
        puts message_out("Tailed last #{(logSize < tailsize) ? logSize : tailsize} bytes "\
                         "of [#{LOGFILES[aIdx]}]")
        log.close

        debug(EXIT, 'tail_log_file')

    end  #  tail_log_file

    ###############################################################################################
    ##   Method Name    :-  display_options
    ##   Description    :-  This method displays the available options.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def display_options

        debug(ENTRY, 'display_options')

        optionKeys = $options.keys.sort { |a,b| a.to_s <=> b.to_s }

        optionKeys.each_with_index do |key, idx|
            puts "#{idx + 1}) #{$options[key][OPTION_MSG_IDX]}"\
                 "[#{$options[key][OPTION_VALUE_IDX]}]"
        end

        print "\nSelect option to change (1 - #{optionKeys.size}) 'x|X' to exit..."
        selection = $stdin.gets.strip!

        if ((selection.empty?)  || (selection =~ /^(x|X)$/) || (selection =~ /\D/))
            raise ForcedExit.new(selection)
        end

        selection = (selection.to_i - 1)
        if ((selection < 0) || (selection >= optionKeys.size))
            raise ForcedExit.new("Invalid selection: [#{selection + 1}]")
        end

        option = optionKeys[selection]

        print "\nCurrent value #{$options[option][OPTION_VALUE_IDX]}."\
                " Enter new value(#{OPTION_TYPE[$options[option][OPTION_INP_IDX]]}),"\
                " 'x|X' to exit..."
        newValue = $stdin.gets.strip!

        raise ForcedExit.new(newValue) if ((newValue.empty?) || (newValue =~ /^(x|X)$/))

        if ((newValue == 't') || (newValue == 'T'))
            newValue = true
        elsif ((newValue == 'f') || (newValue == 'F'))
            newValue = false
        elsif (newValue.to_i > 0)
            newValue = newValue.to_i
        else
            newValue = 1
        end

        change_config_option_value(option,
                                   newValue,
                                   $options[option][OPTION_MSG_IDX],
                                   ":#{$options[option][OPTION_INP_IDX].to_s}")

        debug(EXIT, 'display_options')

    end  #  display_options

    ###############################################################################################
    ##   Method Name    :-  do_code_inspection
    ##   Description    :-  This method performs some basic checks on a file.  For this function
    ##                      to be effective all methods in the script in question should ideally
    ##                      have been constructed using the 49er tool which adds
    ##                      markers this function depends upon.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def do_code_inspection(filename)

        debug(ENTRY, 'do_code_inspection')

        contents = IO.readlines(filename)

        backupname = File.basename(filename.gsub(/\\/, '/'))
        backupPath = "#{$path[:TEMP]}/#{backupname}_#{Time.new.strftime('%Y_%m_%d_%H_%M_%S')}"
        File.open(backupPath, "w+") { |f| f.puts contents }

        @warningsArray = []
        puts message_out("Inspecting file[#{filename}].")
        check_method_structure(contents, filename)
        check_instance_variables(contents, filename)
        check_unused_functions(contents, filename)

        previousLine = "nil"
        contents.each_with_index do |line, index|

            #  Check for unresolved todos
            if (line =~ /\bTODO\b/)

                add_warning(filename, index + 1, 0, "Unresolved todo [#{line.strip}].")
            end

            #  Check for trailing whitespace.
            if (line =~ /\s+$/)

                contents[index].gsub!(/\s+$/, "")
            end

            #  Check for trailing vertical tabs.
            if (line =~ /\v+$/)

                contents[index].gsub!(/\v+$/, "")
            end

            #  Check for consecutive blank lines.
            if ((line =~ /^\s*$/) && (previousLine =~ /^\s*$/))

                add_warning(filename, index, 0, "Blank line at line [#{index + 1}].")
            end
            check_line_length(filename, line, index)
            previousLine = line
        end

        File.open(filename, 'w') { |f| f.puts contents }

        if (@warningsArray.size > 0)

            @warningsArray.each { |warning| puts warning }
        else

            puts message_out("No problems found")
        end

        debug(EXIT, 'do_code_inspection')

    end  #  do_code_inspection
    
    ###############################################################################################
    #  Method      :- timeString_to_seconds
    #  Description :- This method converts a timestring to seconds.
    #  Parameters  :- aTimeString - The timestring in convert.
    #  Return Value:- The time in seconds.
    ############################################################################################### 
    def timeString_to_seconds(aTimeString)

        parts = aTimeString.split(":")

        hours = parts[0].to_i
        minutes = parts[1].to_i
        seconds = (parts[2] == nil) ? 0 :  parts[2].to_i      

        pause_until_keystroke("#{aTimeString} in seconds is #{(hours * 3600) + (minutes * 60) + seconds}")

    end  #  timeString_to_seconds 
    
    ###############################################################################################
    #  Method      :- seconds_to_timeString
    #  Description :- This method converts a time in seonds to a timestring.
    #  Parameters  :- aSecondsValue - The time in seconds to convert.
    #  Return Value:- A formatted timestring.
    ############################################################################################### 
    def seconds_to_timeString(aSecondsValue)

        negative = (aSecondsValue < 0) ? true : false
        aSecondsValue *= -1 if negative
        secs = aSecondsValue.to_i
        h = secs / 3600
        secs -= (h * 3600)
        m = secs / 60
        secs -= (m * 60)
        s = secs        
        time = "%d:%02d:%02d" % [ h,m,s]
        pause_until_keystroke("#{aSecondsValue} seconds is "\
                              "#{(negative)? '-' : ''}#{time} in H:MM:SS")            
    end  #  seconds_to_timeString

    ###############################################################################################
    ##   Method Name    :-  GetMethodNames
    ##   Description    :-  This method reads all method names from a file.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def get_method_names(aFilename)

        debug(ENTRY, "GetMethodNames")
        debug(INFO, aFilename)
        contents = IO.readlines(aFilename)
        contents.each do |line|
            if line =~ /\s*def\s([a-zA-Z0-9]*)\b/
                puts "#{$1.capitalize}();"
            end
        end

        debug(EXIT, "GetMethodNames")

    end  #  GetMethodNames
    
    ###############################################################################################
    ##   Method Name    :-  GetWritableFiles
    ##   Description    :-  This method opens all writeable files.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def get_writablefiles()

        debug(ENTRY, "get_writablefiles")
        cache_filenames()
  
        results = Array.new
        $fileList.each do |file|

          if File.writable?(file)
            open_file(file)
          end

        end        

        debug(EXIT, "get_writablefiles")

    end  #  get_writablefiles    

end  #  MFunction

###################################################################################################
##   Module Name    :-  MHelperFunction
##   Description    :-  This module contains helper methods.
###################################################################################################
module MHelperFunction

    ###############################################################################################
    ##   Method Name    :-  check_unused_functions
    ##   Description    :-  This method checks for unused functions in a ruby script.
    ##   Parameters     :-  aContents - Is the contents of a file.
    ##                  :-  filename - the name of the file.
    ##   Return Value   :-  None.
    ###############################################################################################
    def check_unused_functions(aContents, filename)

        debug(ENTRY, "check_unused_functions")

        functionFoundHash = {}
        aContents.to_s.scan(/^\s*def\s(\w+\??)/) do |f|
            functionFoundHash[f[0]] = 0
        end

        aContents.each_with_index do |line, idx|
            if ((line !~ /^\s*#/) &&
                (line !~ /^\s*end\W*/) &&
                (line !~ /^\s*debug/))

                if (line =~ /((#{functionFoundHash.keys.join('|')}))/)
                    if (functionFoundHash[$1] != nil)

                        functionFoundHash[$1] += 1
                    end
                end
            end
        end

        functionFoundHash.each do |key, value|

            atLine = 0
            if (value <= 1 )

                aContents.each_with_index do |line, index|
                    atLine = index if (line =~ /^\s*def\s#{key}/)
                end
                add_warning(filename, atLine + 1, 0, "Unused function #{key}"\
                                                     " -> Called #{value} in [#{filename}]")
            end unless (key =~ /#{IGNORE_UNUSED_FUNCTIONS}/)
        end

        debug(EXIT, "check_unused_functions")

    end  #  check_unused_functions

    ###############################################################################################
    ##   Method Name    :-  check_method_structure
    ##   Description    :-  This method checks that methods are correctly structured.
    ##   Parameters     :-  contents - the contents of a file.
    ##                  :-  filename - the filename.
    ##   Return Value   :-  None.
    ###############################################################################################
    def check_method_structure(contents, filename)

        debug(ENTRY, 'check_method_structure')

        contents.each_with_index do |line, index|

            if (line =~ /\b(\w*)\b[-\s]+DescriptionMissing/)

                outputLine = "Description missing for [#{$1}] at line [#{index + 1}]."
                add_warning(filename,  index + 1,  contents[index + 1].length, outputLine)
            end

            if (line !~ /^#/) && (line =~ /This\smethod\s*$/)

                outputLine = "Missing method description at line [#{index + 1}]."
                add_warning(filename, index + 1, 0, outputLine)
            end

            if (line =~ /(^\s+def\s)(\w*)/)
                 functionHeader = "#{$1}#{$2}"
                 functionName = $2

                 badlyEnded = false
                 keepLooking = true
                 startLine =  (index + 1)
                 while (keepLooking)

                    if (contents[startLine] =~ /^\s+def\s/)
                        badlyEnded = true
                        keepLooking = false
                    elsif (contents[startLine] =~ /^.*end\s*#\s*#{functionName}/)
                        badlyEnded = false
                        keepLooking = false
                    else
                        keepLooking = true
                    end

                    startLine += 1
                    if (startLine == contents.size)
                        keepLooking = false
                    end
                 end

                 if (badlyEnded)
                     outputLine = "#{functionHeader.strip!} function end not marked"\
                                  "[#{index + 1}]."
                     add_warning(filename, index + 1, 0, outputLine)
                 end

            end

        end

        debug(EXIT, 'check_method_structure')

    end # check_method_structure

    ###############################################################################################
    ##   Method Name    :-  add_warning
    ##   Description    :-  This method stores a warning about the file.
    ##   Parameters     :-  aFilename - the file.
    ##                  :-  aLine - the line.
    ##                  :-  aColumn - the column.
    ##                  :-  aMessage - a message_out.
    ##   Return Value   :-  None.
    ###############################################################################################
    def add_warning(aFilename, aLine, aColumn, aMessage)

        debug(ENTRY, 'add_warning')

        gap = ((150 - aMessage.length) > 0) ? (' ' * (150 - aMessage.length)) : 250
        @warningsArray <<  "\t#{aMessage}#{gap}file:#{aFilename} line:#{aLine} char:#{aColumn}\n"

        debug(EXIT, 'add_warning')

    end  #  add_warning

    ###############################################################################################
    ##   Method Name    :-  check_instance_variables
    ##   Description    :-  This method checks for unneccessary instance variables.
    ##   Parameters     :-  aFileContents - the contents of a file.
    ##                  :-  aFilename - the name of the file.
    ##   Return Value   :-  None.
    ###############################################################################################
    def check_instance_variables(aFileContents, aFilename)

        debug(ENTRY, 'check_instance_variables')

        methodHash = Hash.new()
        method = nil

        aFileContents.each_with_index do |line, index|

            if (line =~ /^\W*\bdef.(\w*)\b/)
                method = $1
                methodHash[method] = Hash.new
            end

            if (method)

                if (line =~ /\b@/)
                    line.scan(/@\w*\b/) { |word| methodHash[method][word] = (index + 1) }
                end
            else
                if (line =~ /\b@/)
                    line.scan(/@\w*\b/) do |word|

                        methodHash.each do |m, hash|
                            hash[word] = 0
                        end
                    end
                end
            end

            method = nil if (line =~ /^\W*\bend.*#{method}/)

        end

        methodHash.each do |name, instanceVarHash|

            instanceVarHash.each do |var, line|

                keyFound = false
                methodHash.each do |reMethod, reVarHash|

                    keyFound = true if ((name != reMethod) && (reVarHash[var] != nil))

                end

                if (keyFound == false)
                    outputLine = "[#{var}] on line [#{line}] unused elsewhere."
                    add_warning(aFilename, line, 0, outputLine)
                        end
                    end
                end

        debug(EXIT, 'check_instance_variables')

    end  #  check_instance_variables

    ###############################################################################################
    ##   Method Name    :-  check_line_length
    ##   Description    :-  This method checks that a line of code does not exceed the max allowed.
    ##   Parameters     :-  aFileName - The name of the file.
    ##                  :-  aLine - The actual line of the file we are checking.
    ##                  :-  aIndex - The line number.
    ##   Return Value   :-  None.
    ###############################################################################################
    def check_line_length(aFileName, aLine, aIndex)

        untabbedline = aLine.gsub(/\t/, "#{'X' * TABSIZE}")

        if (untabbedline.length > MAX_LINE_LENGTH)

            outputLine = "Line [#{aIndex + 1}] exceeds #{MAX_LINE_LENGTH}"\
                             "char limit[#{untabbedline.length}]."

            add_warning(aFileName, aIndex + 1, aLine.length, outputLine)

        end

    end  #  check_line_length

    ###############################################################################################
    ##   Method Name    :-  link_to_previous_log
    ##   Description    :-  This method finds all other logfiles in the same directory as the log
    ##                      passed as a parameter.
    ##   Parameters     :-  aFilePath - Path of the logfile to detect older backed up logs.
    ##   Return Value   :-  None.
    ###############################################################################################
    def link_to_previous_log(aFilePath)

        link = "No previous logfile"
        allLogfiles = []
        Find.find(File.dirname(aFilePath)) do |f|

            if (f =~ /\.log$/)
                allLogfiles << f
            end
        end
        allLogfiles.delete_if { |f| f == aFilePath }
        allLogfiles.sort! do |a,b|
            File.stat(a).ctime <=> File.stat(b).ctime
        end

        if (allLogfiles.size > 0)
            lastButOneFile = allLogfiles[0]
            link = "Previous Logfile: file:#{lastButOneFile} "\
                    "line:#{File.open(lastButOneFile, File::RDONLY).to_a.size}"
        end

        link

    end  #  link_to_previous_log

    ###############################################################################################
    ##   Method Name    :-  wrap_description
    ##   Description    :-  This method wraps a long line for the create_method_template et al.
    ##   Parameters     :-  description - The description of a function.
    ##   Return Value   :-  None.
    ###############################################################################################
    def wrap_description(description = '')

        desc = nil
        while (description.size >= 69)
            if (!desc)
                desc = ''
                desc << description.slice!(0..57) << "\n"
            else
                desc << "#{' ' * 4}###{' ' * 22}" + description.slice!(0..69) << "\n"
            end
        end
        if (!desc) && (description.size != 0)
            desc = description
        elsif (desc) && (description.size != 0)
            desc << "#{' ' * 4}###{' ' * 22}" + description
        elsif (!desc) && (description.size == 0)
             desc = "DescriptionMissing"
        end

        desc

    end  #  wrap_description

    ###############################################################################################
    ##   Method Name    :-  wrap_parameters
    ##   Description    :-  This method wraps parameters for the create_method_template et al.
    ##   Parameters     :-  parameters - parameters for a function.
    ##   Return Value   :-  None.
    ###############################################################################################
    def wrap_parameters(parameters = [])

        params = "Parameters#{' ' * 5}:-  None."
        if (parameters.size > 0)

            eolChar = (parameters.size > 1) ? "\n" : ""
            params = "Parameters#{' ' * 5}:-  #{parameters[0]} - DescriptionMissing#{eolChar}"

            (1...parameters.size).each do |idx|

                eolChar = (idx < parameters.size - 1) ? "\n" : ""
                params += "#{' ' * 4}###{' ' * 18}:-  "\
                            "#{parameters[idx]} - DescriptionMissing#{eolChar}"

            end if (parameters.size > 1)

        end

        params

    end  #  wrap_parameters

    ###############################################################################################
    ##   Method Name    :-  add_template_to_file
    ##   Description    :-  This method adds a new method to a file.
    ##   Parameters     :-  aTemplate -  The method template.
    ##                  :-  aFilename - The file to add it to.
    ##                  :-  aLine - The line to add it at.
    ##   Return Value   :-  None.
    ###############################################################################################
    def add_template_to_file(aTemplate, aFilename, aLine)

        debug(ENTRY, 'add_template_to_file')

        #  Read the contents of 49er's config file.
        contents = IO.readlines(aFilename)
        lineToInsertAt = (!contents[aLine]) ?  contents.size - 1 : aLine
        if (contents.size > 0)

            contents[lineToInsertAt] = aTemplate + contents[lineToInsertAt]
        else

            contents[0] << aTemplate
        end

        file = File.new(aFilename, "w+")
        file.puts contents
        file.close

        debug(EXIT, 'add_template_to_file')

    end  #  add_template_to_file

    ###############################################################################################
    ##   Method Name    :-  cache_filenames
    ##   Description    :-  This method preloads the file index.
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def cache_filenames()

        debug(ENTRY, 'cache_filenames')

        $fileList = []

        quarry_for(false) if (!File.exist?($PROJECT_INDEX_FILENAME))
        puts message_out("Filelist:[#{File.basename($PROJECT_INDEX_FILENAME)}]."\
                         " Updated[#{File.stat($PROJECT_INDEX_FILENAME).mtime}]")
        $fileList = IO.readlines($PROJECT_INDEX_FILENAME).collect { |file| file.chomp! }

        #  Ignore out of date entries.
        $fileList.delete_if { |file| FileTest.exists?(file) == false }

        debug(EXIT, 'cache_filenames')

    end  #  cache_filenames

    ###############################################################################################
    ##   Method Name    :-  pause_until_keystroke
    ##   Description    :-  This method stops the console closing
    ##   Parameters     :-  None.
    ##   Return Value   :-  None.
    ###############################################################################################
    def pause_until_keystroke(msg = "Press any key to exit...")

        puts message_out(msg)
        gets

    end  #  pause_until_keystroke

    ###############################################################################################
    ##   Method Name    :-  open_text
    ##   Description    :-  This method opens a named file in your specified text editor.
    ##   Parameters     :-  aFilename - The file to open.
    ##                  :-  aLine - The line to open the file at.
    ##   Return Value   :-  None.
    ###############################################################################################
    def open_text(aFilename, aLine = 0)

        debug(ENTRY, "open_text")

        aFilename.strip!

        if (File.exist?(aFilename) == false)
            raise ForcedExit.new("File [#{aFilename}] does not exist")
        end

        begin
            system(`start #{$path[:TEXT_EDITOR_EXE]} #{aFilename}(#{aLine})`)
        rescue
            raise ForcedExit.new("Could not open #{aFilename} using #{$path[:TEXT_EDITOR_EXE]}")
        end

        debug(EXIT, "open_text")

    end  #  open_text

    ###############################################################################################
    ##   Method Name    :-  message_out
    ##   Description    :-  This method prints a header to the console.
    ##   Parameters     :-  aMessage - A message_out to display..
    ##   Return Value   :-  String - A formatted message_out.
    ###############################################################################################
    def message_out(aMessage)

        msg = []
        0.step(aMessage.size, 79) do |i|
            msg << "#{aMessage[i, 79]}"
        end
        h1 = ("=" * 79)
        (h1 + "\n" + msg.to_s + "\n" + h1)

    end  #  message_out

    ###############################################################################################
    ##   Method Name    :-  change_config_current_search_file
    ##   Description    :-  This method changes the Current Search Directory
    ##                      in the config file.
    ##   Parameters     :-  aProject - The name of the project.
    ##   Return Value   :-  None.
    ###############################################################################################
    def change_config_current_search_file(aProject)

        debug(ENTRY, "change_config_current_search_file")

        configFile = IO.readlines($path[:INIT])
        configFile.each_with_index do |line, idx|

            if (line =~ /^(\s*\WCURRENT_PROJECT)/)

                configFile[idx] = "#{$1} = :#{aProject}\n"
                break
            end
        end

        cfgFile = File.new($path[:INIT], "w+")
        cfgFile.puts(configFile)
        cfgFile.close

        debug(EXIT, "change_config_current_search_file")

    end  #  change_config_current_search_file

    ###############################################################################################
    ##   Method Name    :-  change_config_option_value
    ##   Description    :-  This method change the value of an option in the
    ##                      config file.
    ##   Parameters     :-  aKey - The option key.
    ##                  :-  aValue - The value to set for the option.
    ##                  :-  aMessage - The message_out related to the option.
    ##                  :-  aAllowableInputKey - A symbol representing the allowable input.
    ##   Return Value   :-  None.
    ###############################################################################################
    def change_config_option_value(aKey, aValue, aMsg, aAllowableInputKey)

        debug(ENTRY, "change_config_option_value")

        contents = IO.readlines($path[:CONFIG])
        contents.map! do |line|

             if (line =~ /^\s*:#{aKey}/)
                "\t\t:#{aKey}\t=>\t[#{aValue}, \'#{aMsg}\', #{aAllowableInputKey}],\n"
             else
                line
             end
        end

        cfgFile = File.new($path[:CONFIG], "w+")
        cfgFile.puts(contents)
        cfgFile.close

        debug(EXIT, "change_config_option_value")

    end  #  change_config_option_value

    ###############################################################################################
    ##   Method Name    :-  display_file_list
    ##   Description    :-  This method presents a list of files to choose from, if
    ##                      a valid choice is made the file is opened.
    ##   Parameters     :-  aFileList - An array of filenames.
    ##   Return Value   :-  None.
    ###############################################################################################
    def display_file_list(aFileList)

        debug(ENTRY, "display_file_list")

        if (aFileList.size == 1)

            open_file(aFileList[0])
            raise QuietExit.new("One file found, closing quietly")
        else

            puts message_out("49er has found #{aFileList.size} files.")
            filesToDisplay = $options[:FILES_TO_DISPLAY][OPTION_VALUE_IDX]
            aFileList.each_with_index do |file, idx|

                #  If we are displaying a limited number of files at a time.
                if ((idx > 0) && (idx % filesToDisplay == 0))

                    msg = "Select file to open (1 - #{idx} or all|*
                    ) or "\
                            "display next #{filesToDisplay} files"
                    process_selections(msg, idx, aFileList)
                end

                showFullPaths = $options[:SHOW_FULL_PATHS][OPTION_VALUE_IDX]
                puts "#{idx + 1}) "\
                        "#{(showFullPaths) ? aFileList[idx] : File.basename(aFileList[idx]) }"
            end

            msg = "Select file to open (1 - #{aFileList.size}  or all)"
            process_selections(msg, aFileList.size, aFileList)
        end

        debug(EXIT, "display_file_list")

    end  #  display_file_list

    ###############################################################################################
    ##   Method Name    :-  process_selections
    ##   Description    :-  This method processes the user selections before processing.
    ##   Parameters     :-  aMsg - a prompt for input.
    ##                  :-  aIdx - a count of the files that have been displayed.
    ##                  :-  aFileList - a list of filenames.
    ##   Return Value   :-  None.
    ###############################################################################################
    def process_selections(aMsg, aIdx, aFileList)

        debug(ENTRY, "process_selections")

        print "\n#{aMsg} 'x|X' to exit..."
        selections = $stdin.gets
        raise ForcedExit.new(selections.strip) if (selections =~ /^(x|X)$/)

        fileProcessed = false
        if (/(\d[,|\s|\d]*)/.match(selections))

            selections.split(/,/).each do |sel|

                sel.strip!
                if (sel =~ /\d$/)

                    sel = sel.to_i - 1
                    if ((sel >= 0) && (sel < aIdx) && (File.exist?(aFileList[sel])))
                        open_file(aFileList[sel])
                    end
                end
            end
            raise QuietExit.new("File processing completed.")
        elsif (/(all|ALL|\*)/.match(selections))

            aFileList.each { |f| open_file(f) }
            raise QuietExit.new("File processing completed.")
        end

        debug(EXIT, "process_selections")

    end  #  process_selections

    ###############################################################################################
    ##   Method Name    :-  open_file
    ##   Description    :-  This method handles the opening of a selected file
    ##   Parameters     :-  aFilename - a file to process.
    ##   Return Value   :-  None.
    ###############################################################################################
    def open_file(aFilename)

        debug(ENTRY, "open_file[#{aFilename}]")

        if (aFilename.downcase =~ /#{SELFOPENER}$/i)

            debug(INFO, "SelfOpening #{aFilename}")
            uri = aFilename.split(/\//).map! { |part| "\"" + part + "\"" }.join('\\')
            `start #{uri} #{uri}`
        elsif (aFilename.downcase =~ /#{OPENFOLDER}$/i)
            debug(INFO, "Mot SelfOpening #{aFilename}")
            uri = File.dirname(aFilename).gsub(/\//, "\\")

            @folderOpened = [] unless @folderOpened
            `start /MAX explorer /e, #{uri}` unless (@folderOpened.include?(uri))
            @folderOpened << uri
        else
            open_text(aFilename)
        end

        debug(EXIT, "open_file")

    end  #  open_file

    ###############################################################################################
    ##   Method Name    :-  build_drill_results_frame
    ##   Description    :-  This method builds a context frame for search results.
    ##   Parameters     :-  aFilename - The file the search results come from.
    ##                  :-  aFileContents - The contents of the file.
    ##                  :-  aIndex - The first line of the serach results.
    ##   Return Value   :-  a collection of lines to display.
    ###############################################################################################
    def build_drill_results_frame(aFilename, aFileContents, aIndex)

        debug(ENTRY, "build_drill_results_frame")

        frameSize = $options[:RESULTS_CONTEXT_SIZE][OPTION_VALUE_IDX]
        fileSize = aFileContents.size
        buffer = (frameSize / 2)
        startIndex = ((aIndex - buffer) < 0) ? 0 : (aIndex - buffer)
        endIndex = ((aIndex + buffer) > fileSize)? fileSize : (aIndex + buffer)
        frame = ''
        maxCodeLineSize = 80
        (startIndex..endIndex).each do |line|

            aFileContents[line].chomp! unless (aFileContents[line] == nil)
            outputLine = "#{aFileContents[line]}"
            if (outputLine.length > maxCodeLineSize)
              outputLine = outputLine[0, maxCodeLineSize]
            end
            lineLength = (300 - outputLine.length)
            gap = ' ' * ((lineLength > 0) ? lineLength : 300)
            frame << "#{line + 1}. #{outputLine}#{gap}file:#{aFilename} line:#{line + 1}\n"
        end

        debug(EXIT, "build_drill_results_frame")

        frame

    end  #  build_drill_results_frame

    ###############################################################################################
    ##   Method Name    :-  print_drill_results
    ##   Description    :-  This method prints Drill results to the Command Results window.
    ##   Parameters     :-  aResults - A Hash of search results.
    ##                  :-  aPattern - the search pattern used.
    ##   Return Value   :-  None.
    ###############################################################################################
    def print_drill_results(aResults, aPattern)

        debug(ENTRY, "print_drill_results")

        puts message_out("Found  << #{aPattern} >> in #{aResults.keys.size} "\
                     "file#{(aResults.keys.size == 1) ? '': 's'}.")

        aResults.each do |filename, frameArray|

            puts message_out(filename.upcase)
            frameArray.each do |frame|

                puts frame
                puts '-' * 79
            end
        end

        debug(EXIT, "print_drill_results")

    end  #  print_drill_results

    ###############################################################################################
    ##   Method Name    :-  debug
    ##   Description    :-  This method adds statements to the 49er log.
    ##   Parameters     :-  aStatus - The logging level.
    ##                  :-  aText - The text of the logging statement, or an arry of statements.
    ##   Return Value   :-  None.
    ###############################################################################################
    def debug(aStatus, *aText)

        if (DEBUG_LEVEL.include?(aStatus))
            if (MLog.const_defined? :LOG)

                LOG.output(aStatus, *aText)
            end

            if ($options[:LOGTOCONSOLE][OPTION_VALUE_IDX])
                begin
                    pause_until_keystroke(aText.join(', '))
                rescue
                    #
                end
            end
        end

    end  #  debug

    ###############################################################################################
    ##   Method Name    :-  find_pattern_in_file
    ##   Description    :-  This method searches for a pattern in the contents of files
    ##   Parameters     :-  aFilename - a file to search in.
    ##                  :-  aRegex - a regular expression.
    ##                  :-  aResultsHash - a container for the results.
    ##                  :-  aMaxResults - the max number of results to return.
    ##   Return Value   :-  None.
    ###############################################################################################
    def find_pattern_in_file(aFilename, aRegex, aResultsHash, aMaxResults)

        debug(ENTRY, "find_pattern_in_file")

        contents = IO.readlines(aFilename)
        frameSize = $options[:RESULTS_CONTEXT_SIZE][OPTION_VALUE_IDX]
        mergeResults = $options[:MERGE_RESULTS][OPTION_VALUE_IDX]
        contents.each_with_index do |line, index|
            break if ((aMaxResults != nil) && (aMaxResults <= 0))
            if (aRegex.match(line))
                #  aResultsHash[filename] is an array where each element is a frame containing
                #  a number of lines of code.
                aResultsHash[aFilename] = Array.new unless (aResultsHash[aFilename])
                aMaxResults -= 1 unless (aMaxResults == nil)
                if (mergeResults) && (aResultsHash[aFilename].size > 0)

                    #  If this line is already in the previous results, skip it.
                    if (aResultsHash[aFilename].last =~ /line:(\d+)\Z/)
                        previousEnding = $1.to_i
                        if (((index + 1) - (frameSize.to_i / 2)) <= previousEnding)

                            new_index = (previousEnding + (frameSize.to_i / 2))
                            aResultsHash[aFilename].last << build_drill_results_frame(aFilename,
                                                                                      contents,
                                                                                      new_index)
                        else
                            aResultsHash[aFilename] <<  build_drill_results_frame(aFilename,
                                                                                  contents,
                                                                                  index)
                        end
                    end

                else

                    aResultsHash[aFilename] << build_drill_results_frame(aFilename,
                                                                         contents,
                                                                         index)
                end

            end

        end

        debug(EXIT, "find_pattern_in_file")

        aMaxResults

    end  #  find_pattern_in_file

    ###############################################################################################
    ##   Method Name    :-  find_ruby_method_in_file
    ##   Description    :-  This method searches for a method definition in a file
    ##   Parameters     :-  filename - a file to search in.
    ##                  :-  aKeyWord - a method name to locate.
    ##   Return Value   :-  True if found false otherwise.
    ###############################################################################################
    def find_ruby_method_in_file(filename, aKeyWord)

        debug(ENTRY, "find_ruby_method_in_file")

        contents = IO.readlines(filename)
        found = false

        contents.each_with_index do |line, index|

            #  If the line contains the method name, comments ignored.
            if (line =~ /^\s*def\s#{aKeyWord}/)

                 open_text(filename, index + 1)
                 found = true
                 break
            end

        end

        debug(EXIT, "find_ruby_method_in_file")

        found

    end  #  find_ruby_method_in_file

    ###############################################################################################
    ##   Method Name    :-  find_javascript_method_in_file
    ##   Description    :-  This method searches for a method definition in a file
    ##   Parameters     :-  filename - a file to search in.
    ##                  :-  aKeyWord - a method name to locate.
    ##   Return Value   :-  True if found false otherwise.
    ###############################################################################################
    def find_javascript_method_in_file(filename, aKeyWord)

        debug(ENTRY, "find_javascript_method_in_file")

        contents = IO.readlines(filename)
        found = false

        contents.each_with_index do |line, index|

            #  If the line contains the method name, comments ignored.
            if (line =~ /^\s*function\s#{aKeyWord}/)

                 open_text(filename, index + 1)
                 found = true
                 break
            end

        end

        debug(EXIT, "find_javascript_method_in_file")

        found

    end  #  find_ruby_method_in_file
end  #  MHelperFunction
