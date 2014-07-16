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
require 'date'

module MLog

    ###########################################################################
    #
    #   Method Name  :- init_log
    #   Description  :- This class method initialises the logfile.
    #   Parameters   :- None.
    #   Return Value :- None.
    ###########################################################################
    def init_log(aLogFileName, aMaxsize)
        finalize_log()
        const_set :LOG, CLogger.new(aLogFileName, aMaxsize)
    end  #  init_log

    ###########################################################################
    #
    #   Method Name  :- finalize_log
    #   Description  :- This method ensures that the logger is closed properly.
    #   Parameters   :- None.
    #   Return Value :- None.
    ###########################################################################
    def finalize_log
        if MLog.const_defined? :LOG
            LOG.close
            remove_const :LOG
        end
    end  #  finalize_log

    ###############################################################################################
    ##   Class Name   :- CLogger
    ##   Description  :- This class
    ###############################################################################################
    class CLogger

        ###########################################################################
        #
        #   Method Name  :- initialize
        #   Description  :- This method initialises the logfile.
        #   Parameters   :- aLogFileName - The nme of the new logfile.
        #                :- aMaxsize - The max size(KB) of the new log.
        #   Return Value :- None.
        ###########################################################################
        def initialize(aLogFileName, aMaxsize)

            @logFileName = aLogFileName
            @maxSize = (aMaxsize * 1024)
            open()

        end  #  initialize

        ###############################################################################################
        ##   Method Name    :-  close
        ##   Description    :-  This method closes the logfile.
        ##   Parameters     :-  None.
        ##   Return Value   :-  None.
        ###############################################################################################
        def close

            @log.close() if @log
            @log = nil

        end  #  close

        ###########################################################################
        #
        #   Method Name  :- output
        #   Description  :- This method adds an entry to the logfile.
        #   Parameters   :- aStatus - The log status.
        #                :- aMsg - The log entry.
        #   Return Value :- None - nil.
        ###########################################################################
        def output(aStatus, *aText)

            open() if (!@log)

            size = @log.stat.size
            if (size > @maxSize)
                back_up_log()
            end

            begin
                t = Time.new.strftime('%Y/%m/%d %H:%M:%S')

                if (aText.respond_to?('each'))
                    aText.each do |m|
                        if (m.class.name == 'Array')
                            m.each do |e|
                                @log.puts("[#{t}][#{aStatus}] #{e}")
                            end
                        elsif (m.class.name == 'Hash')
                            m.each do |k,v|
                                @log.puts("[#{t}][#{aStatus}] #{k}->#{v}")
                            end
                        else
                            @log.puts("[#{t}][#{aStatus}] #{m}")
                        end
                    end
                 else
                    @log.puts("[#{t}][#{aStatus}] #{aText}")
                 end
            rescue Exception => ex
                raise Exception.new("CLogger::Error writing to log(#{ex})")
            end
            
            nil

        end  #  output

        def debug(*aText)
            output('DEBUG', *aText)
        end
        def info(*aText)
            output('INFO', *aText)
        end
        def error(*aText)
            output('ERROR', *aText)
        end
        def warning(*aText)
            output('WARN', *aText)
        end        

        private

        ###############################################################################################
        ##   Method Name    :-  open
        ##   Description    :-  This method opens the logfile.
        ##   Parameters     :-  None.
        ##   Return Value   :-  None.
        ###############################################################################################
        def open()

            begin
                @log = File.new(@logFileName, 'a+')
                @log.sync = true
            rescue
                raise Exception.new("CLogger::Error creating log file")
            end

        end  #  open

        ###############################################################################################
        ##   Method Name    :-  back_up_log
        ##   Description    :-  This method backs up the logfile.
        ##   Parameters     :-  None.
        ##   Return Value   :-  None.
        ###############################################################################################
        def back_up_log()

            begin
                close()
                name, ext = @logFileName.split('.')
                backupname = "#{name}_#{Time.new.strftime('%Y_%m_%d_%H_%M_%S')}.#{ext}"
                File.rename(@logFileName, backupname)
                open()
            rescue
                raise Exception.new("CLogger::Error backing up log file")
            end

        end  #  back_up_log

    end  #  CLogger

end
