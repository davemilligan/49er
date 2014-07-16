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
##   Module Name  :- MInit
##   Description  :- This module contains constants used for 49er.
###################################################################################################
module MInit
    
    HOME = "C:\\49er"
    
    #  Logging Constants
    ENTRY = '>>>>'
    EXIT = '<<<<'
    INFO = 'INF0'
    DEBUG = 'DEBUG'
    WARN = 'WARNING'
    ERROR = 'ERROR'
    
    #  Option index.
    OPTION_VALUE_IDX = 0    #  The value of the option.
    OPTION_MSG_IDX = 1      #  The description of the option that is displayed in the dialog.
    OPTION_INP_IDX = 2      #  The allowable input.
    
    HOME_DIR_IDX = 0
    FILE_EXT_IDX = 1
    EXC_SEARCH_DIRS = 2
    PREFERRED_IDX = 3
    
    #  Specific paths used by the 49er.
    $path =     {
        :CONFIG             =>  "#{HOME}\\bin\\fortyninercfg.rb",
        :INIT               =>  "#{HOME}\\bin\\fortyninerinit.rb",
        :LOG                =>  "#{HOME}\\log",
        :INDEX              =>  "#{HOME}\\index",
        :TEXT_EDITOR_PATH   =>  'C:\\Program Files (x86)\\TextPad 5\\',
        :TEXT_EDITOR_EXE    =>  'TextPad',
        :TEMP               =>  "#{HOME}\\temp",
        :JAVASCRIPT_SRC     =>  "#{HOME}\\javascript\\fortyniner.js",
        :JAVASCRIPT_DISPLAY =>  "#{HOME}\\javascript\\javascript.html",
        :STDERR             =>  "#{HOME}\\log\\stderr.log",
    }
    
    
    OPTION_TYPE = {
        :TRUE_FALSE => 't|T|f|F',
        :NUMERIC => 'a number'
    }

   
    #  Replace all backslashes with forwardslashes.
    $path.keys.each { |path| $path[path].gsub!(/\\/, "/") }

    $CURRENT_PROJECT = :FILEPASS

end
