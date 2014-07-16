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

require 'fortyninerinit'
require 'fortyninercfg'
require 'fortyninerdev'
require 'fortyninerlogger'
require 'templates'
require 'win32ole'
require 'getoptlong'
require 'find'
require 'benchmark'
require 'ftools'

include MConfig
include MHelperFunction
include MFunction
include MLog

#  Add the two 49er logfiles to the start of the log file array.
LOGFILES.unshift($path[:STDERR])
LOGFILES.unshift("#{$path[:LOG]}/fortyniner.log")

LOGFILES.each { |k| k.gsub!(/\\/, "/") }

PROJECTS[:FORTYNINER] = ["#{File.dirname(__FILE__)}/../", '(.*)', "(#{File.dirname(__FILE__)}/../index|#{File.dirname(__FILE__)}/../log|#{File.dirname(__FILE__)}/../temp|\.svn)", 1]

if (!PROJECTS[$CURRENT_PROJECT])
     puts "Current Project Invalid #{$CURRENT_PROJECT.to_s}, resetting to 49er"
     $CURRENT_PROJECT = :FORTYNINER     
     $stdin.gets
end

#  Constants for key values used throughout.
$SEARCH_HOME = PROJECTS[$CURRENT_PROJECT][HOME_DIR_IDX]
$SEARCH_EXTENSIONS = PROJECTS[$CURRENT_PROJECT][FILE_EXT_IDX]
$EXCLUDESEARCHDIRS = PROJECTS[$CURRENT_PROJECT][EXC_SEARCH_DIRS]
$PROJECT_INDEX_FILENAME = "#{$path[:INDEX]}/#{$CURRENT_PROJECT.to_s}.idx"

if (!$SEARCH_HOME) || (!FileTest.directory?($SEARCH_HOME))
     puts "Current SEARCH_HOME Invalid #{$SEARCH_HOME}"
     $stdin.gets
end

#  Replace all backslashes with forwardslashes.
PROJECTS.keys.each do |url|
    PROJECTS[url][HOME_DIR_IDX].gsub!(/\\/, "/")
    #PROJECTS[url][EXC_SEARCH_DIRS].gsub!(/\\/, "/") unless (!PROJECTS[url][EXC_SEARCH_DIRS])
end

ENV['PATH'] = $path[:TEXT_EDITOR_PATH]
$stderr = File.open($path[:STDERR], "a+")

puts message_out("49er Version #{FORTYNINER_VERSION}\n" +
               "Copyright(c) 2007 David Milligan.\n" +
               "This program comes with ABSOLUTELY NO WARRANTY.\n" +
               "Current Project: #{$CURRENT_PROJECT.to_s},\n" +
               "Search Dir: #{$SEARCH_HOME}\n" +
               "Extensions: #{$SEARCH_EXTENSIONS}")

if (File.exists?("#{File.dirname(__FILE__)}/../custom/customFunctions.rb"))
    require "#{File.dirname(__FILE__)}/../custom/customFunctions"
    include MCustomFunction
end



#  SystemExit derived classes used for quitting gracefully.
class ForcedExit < SystemExit; end
class QuietExit < SystemExit; end

#  Command line options.
CONFIG                = '--config'
PROSPECT              = '--prospect'
QUARRY                = '--quarry'
DIG                   = '--dig'
OPTIONS               = '--options'
DRILL                 = '--drill'
FINDMETHOD            = '--findmethod'
FINDJAVASCRIPTMETHOD  = '--findjavascriptmethod'
FINDMETHOD_DIR        = '--findmethoddir'
CREATEMETHOD          = '--createmethod'
CREATECLASS           = '--createClass'
CREATEMODULE          = '--createModule'
LOGFILE               = '--logfile'
FILTERLOGFILE         = '--filterlog'
CLEARLOGFILE          = '--clearlogfile'
QFORUM                = '--qforum'
LOGS                  = '--logs'
INSPECTOR             = '--codecheck'
JAVASCRIPT            = '--javascript'
WRITABLEFILES        = '--writablefiles'

#  Command line flags.
HELP            = '-h'
IGNORECASE      = '-i'
EXACTMATCH      = '-e'
MAX_RESULTS     = '-m'
CURRENT_FILE    = '-f'
LINE_NO         = '-l'
CURRENT_DIR     = '-d'

#  Custom Command Line Options.
SECONDS2TIME    = '--seconds2time'
TIME2SECONDS    = '--time2seconds'
GETMETHODNAMES  = '--getmethodnames'



begin

    MLog.init_log(LOGFILES[0], $options[:MAX_LOGFILE_SIZE][OPTION_VALUE_IDX])

    

    opts = GetoptLong.new(
        [CONFIG,            GetoptLong::NO_ARGUMENT],
        [PROSPECT,          GetoptLong::NO_ARGUMENT],
        [QUARRY,            GetoptLong::NO_ARGUMENT],
        [DIG,               GetoptLong::OPTIONAL_ARGUMENT],
        [OPTIONS,           GetoptLong::NO_ARGUMENT],
        [DRILL,             GetoptLong::REQUIRED_ARGUMENT],
        [FINDMETHOD,        GetoptLong::REQUIRED_ARGUMENT],
        [FINDJAVASCRIPTMETHOD,        GetoptLong::REQUIRED_ARGUMENT],
        [FINDMETHOD_DIR,    GetoptLong::REQUIRED_ARGUMENT],
        [CREATEMETHOD,      GetoptLong::REQUIRED_ARGUMENT],
        [CREATECLASS,       GetoptLong::REQUIRED_ARGUMENT],
        [CREATEMODULE,      GetoptLong::REQUIRED_ARGUMENT],
        [LOGFILE,           GetoptLong::REQUIRED_ARGUMENT],
        [CLEARLOGFILE,      GetoptLong::REQUIRED_ARGUMENT],
        [CURRENT_FILE,      GetoptLong::OPTIONAL_ARGUMENT],
        [IGNORECASE,        GetoptLong::NO_ARGUMENT],
        [EXACTMATCH,        GetoptLong::NO_ARGUMENT],
        [MAX_RESULTS,       GetoptLong::REQUIRED_ARGUMENT] ,
        [LINE_NO,           GetoptLong::REQUIRED_ARGUMENT],
        [CURRENT_DIR,       GetoptLong::REQUIRED_ARGUMENT],
        [HELP,              GetoptLong::NO_ARGUMENT],
        [QFORUM,            GetoptLong::REQUIRED_ARGUMENT],
        [LOGS,              GetoptLong::NO_ARGUMENT],
        [JAVASCRIPT,        GetoptLong::NO_ARGUMENT],
        [INSPECTOR,         GetoptLong::REQUIRED_ARGUMENT],
        [SECONDS2TIME,      GetoptLong::REQUIRED_ARGUMENT],
        [TIME2SECONDS,      GetoptLong::REQUIRED_ARGUMENT],        
        [FILTERLOGFILE,     GetoptLong::REQUIRED_ARGUMENT],
        [GETMETHODNAMES,    GetoptLong::NO_ARGUMENT],
        [WRITABLEFILES,     GetoptLong::NO_ARGUMENT]
    )
    
    ignoreCase = false
    exactMatch = false
    currentFile = nil
    currentDir = nil
    maxResults = 1000000
    lineNumber = 0
    seconds = Benchmark.realtime do
    
        options = {}
        opts.each do |opt, arg|
            LOG.debug("OPT[#{opt}] ARG[#{arg}]")
            args = arg.split(",")
            options[opt] = [arg, args]
        end

        if options[LINE_NO]
            lineNumber = options[LINE_NO][0].to_i
        end
        
        if options[MAX_RESULTS]
            maxResults = options[MAX_RESULTS][0].to_i
        end
        
        if options[CURRENT_FILE]
            currentFile = options[CURRENT_FILE][0]
        end
        
        if options[CURRENT_DIR]
            currentDir = options[CURRENT_DIR][0]
        end
        
        if options[IGNORECASE]
            ignoreCase = true
        end
        
        if options[EXACTMATCH]
            exactMatch = true
        end
        
        if options[CONFIG]
            puts $path[:CONFIG]
            open_text($path[:CONFIG])
        end
        
        if options[LOGS]
            show_logs()
        end
        
        if options[QFORUM]
            query_ruby_forum(*options[QFORUM][1])
        end
        
        if options[PROSPECT]
            prospect_for()
        end
        
        if options[DIG]
            dig_for(ignoreCase, exactMatch, *options[DIG][1])
        end
        
        if options[QUARRY]
            
            quarry_for()
        end
        
        if options[OPTIONS]
            display_options()
        end
        
        if options[CREATEMETHOD]
            if (options[CREATEMETHOD][1].size == 0)
                raise GetoptLong::MissingArgument.new("#{CREATEMETHOD} requires an argument")
            end
            create_method_template(currentFile, lineNumber, *options[CREATEMETHOD][1])
        end
        
        if options[CREATECLASS]
            if (options[CREATECLASS][1].size == 0)
                raise GetoptLong::MissingArgument.new("#{CREATECLASS} requires an argument")
            end
            create_class_template(currentFile, lineNumber, *options[CREATECLASS][1])
        end
        
        if options[CREATEMODULE]
            if (options[CREATEMODULE][1].size == 0)
                raise GetoptLong::MissingArgument.new("#{CREATEMODULE} requires an argument")
            end
            create_module_template(currentFile, lineNumber, *options[CREATEMODULE][1])
        end
        
        if options[FINDMETHOD]
            find_method(options[FINDMETHOD][0])
        end

        if options[FINDJAVASCRIPTMETHOD]
            find_javascript_method(options[FINDJAVASCRIPTMETHOD][0])
        end
        
        if options[FINDMETHOD_DIR]
            find_method_in_current_dir(options[FINDMETHOD_DIR][0], currentDir)
        end
        
        if options[DRILL]
            drill_down(maxResults, ignoreCase, exactMatch, *options[DRILL][1])
        end
        
        if options[LOGFILE]
            tail_log_file(options[LOGFILE][0].to_i)
        end
        
        if options[CLEARLOGFILE]
            clear_log_file(options[CLEARLOGFILE][0].to_i)
        end
        
        if options[HELP]
            show_help()
        end
        
        if options[INSPECTOR]
            do_code_inspection(options[INSPECTOR][0])
        end
        
        if options[JAVASCRIPT]
            load_run_javascript()
        end
        
        if options[SECONDS2TIME]
            seconds_to_timeString(options[SECONDS2TIME][0].to_i)
        end

        if options[TIME2SECONDS]
            timeString_to_seconds(options[TIME2SECONDS][0])
        end
        
        if options[FILTERLOGFILE]
            filter_logfile(currentFile, options[FILTERLOGFILE][1])
        end
        
        if options[GETMETHODNAMES]
            get_method_names(currentFile)
        end
        
        if options[WRITABLEFILES]
            get_writablefiles()
        end        
        
    end

    debug(DEBUG, "#{seconds} seconds")  if ($options[:BENCHMARKING][OPTION_VALUE_IDX])

rescue GetoptLong::Error => ex

    pause_until_keystroke("#{ex.class.name} #{ex.to_s}")

rescue QuietExit => ex

    debug(INFO, ex)

rescue ForcedExit => ex

    msg = "User Action Forced Exit [#{ex}]"
    debug(INFO, msg)
    pause_until_keystroke(msg)

rescue Exception => ex

    msg = "Exception Caught: [#{ex}]"
    debug(ERROR, msg, ex.backtrace)
    pause_until_keystroke("#{msg}," + ex.backtrace.join("\n"))

ensure
    MLog::finalize_log()
end
