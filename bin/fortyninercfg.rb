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
##   Module Name  :- MConfig
##   Description  :- This module contains configuration settings for 49er.
###################################################################################################
module MConfig   
    require 'fortyninerinit'
    include MInit
    
    FORTYNINER_VERSION = '3.0.0'
    
    #  File extensions to be opened by the appropriate application.
    SELFOPENER = "(.jpg|.png|.jpeg|.gif|.bmp|.xls|.xlsx|.doc|.docx|.pdf|.chm|.mp3)"

    #  49er will not try to open files with these extension.
    #  It will however open the containing folder.
    OPENFOLDER = "(.bat|.exe|.so|.bnd)"

    #  Debug levels to process.
    #  [ENTRY, EXIT, INFO, WARN, DEBUG, ERROR]
    DEBUG_LEVEL = [ENTRY, EXIT, INFO, WARN, DEBUG, ERROR]

    #  PROJECTS are any folder that contains files that you would like to index for quick searching
    #  via the 49er interface.
    #  Each of PROJECT's keys(SYMBOLs) points to an array containing the PROJECT directory,
    #  a set of extensions that will identify the filetypes you are interested in and
    #  any exclude key that will identify a folder or part of a filename that indicates that
    #  a particular file or directory is to be ignored.
    #  PROJECTS{ :key =>  [searchdir, (exts), (excludePattern)[, preferredIndex]}
    #  exts should be grouped for a regexp(.rb|.txt|.*)
    #  excludePattern should be grouped for a regexp (a|b)
    #  Change Project CTRL + P
    PROJECTS = {
        :FILEPASS => ["C:\\FastPass\\node", "(.*)", nil, 2],
        :BAAZING => ["C:\\GDrive\\Baazing", "(.*)", nil, 3],
        :REDIS_EXAMPLES => ["C:\\FastPass\\node\\node_modules\\redis", "(.js)", nil, 4]
    }
    
    #  You can add an unlimited number of logfiles here.
    #  These files can be used to either load the last LOG_TAIL_SIZE lines of 
    #  the file(CTRL+L[N]), or to clear the contents of the logfile(ALT+L[N]).
    LOGFILES = []
    
    #  To set an option, all that is needed is to add an appropriate name & set of values here.
    #  This value can then be used in a function elsewhere.
    #  Options for 49er $options { :key => [value, description, OPTION_TYPE] }
    #  Change Options here or use [ALT + O]
    #  OPTIONS CAN ONLY BE true/false(:TRUE_FALSE) OR A WHOLE NUMBER(:NUMERIC).
    $options = {
        :MAX_LOGFILE_SIZE   =>  [10, 'Maximum size of the logfile KB', :NUMERIC],
        :LOG_TAIL_SIZE  =>  [2000, 'Tail size of a logfile in KB', :NUMERIC],
        :FILES_TO_DISPLAY =>  [10, 'Files shown in search results', :NUMERIC],
        :RESULTS_CONTEXT_SIZE =>  [1, 'Set drill context width in search results', :NUMERIC],
        :MERGE_RESULTS  =>  [true, 'Merge drill search results', :TRUE_FALSE],
        :SHOW_FULL_PATHS    =>  [false, 'Show full filepath in dig results', :TRUE_FALSE],
        :SEARCH_FULL_PATHS  =>  [false, 'Search full paths in dig.', :TRUE_FALSE],
        :CASE_SENSITIVE =>  [true, 'Case sensitivity, can be overridden by -i', :TRUE_FALSE],
        :BENCHMARKING   =>  [true, 'Benchmark function calls.', :TRUE_FALSE],
        :LOGTOCONSOLE   =>  [false, 'Show logging in console.', :TRUE_FALSE],
    }   

    
end  #  MConfig
