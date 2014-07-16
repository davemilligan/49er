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

#  The create method tool uses this template to create a new function header.
#  Changing this template may just break the codeInspection tool, so unless you wasnt to
#  fix that tool as well it's probably best to leave this as is.
#  Uses the substitutions array in fortyninerdev.rb.
METHOD_TEMPLATE =<<METHOD_TEMPLATE_END
  /*
   *   Method Name    :-  %s
   *   Description    :-  This method %s
   *   %s
   *   Return Value   :-  None.
   */
  function %s(%s) {    
    debug(">>>>%s")
    alert("%s not implemented.");
    debug("<<<<%s")
  }
METHOD_TEMPLATE_END

#  This template is used to create a class header.
#  Uses the substitutions array in fortyninerdev.rb.
CLASS_TEMPLATE =<<CLASS_TEMPLATE_END
###################################################################################################
##   Class Name     :-  %s 
##   Description    :-  This class %s
###################################################################################################
class %s
end  #  %s
CLASS_TEMPLATE_END
    
#  This template is used to create a module header.
#  Uses the substitutions array in fortyninerdev.rb.
MODULE_TEMPLATE =<<MODULE_TEMPLATE_END
###################################################################################################
##   Module Name   :-  %s 
##   Description   :-  This module %s
###################################################################################################
module %s
end  #  %s
MODULE_TEMPLATE_END
