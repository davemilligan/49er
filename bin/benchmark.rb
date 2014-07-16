#
# benchmark.rb
#
=begin
  2002-04-25: bmbm(): killed unused parameter @fmtstr (gotoken)
  2001-11-26: Time.times renamed Process.times for ruby17 (gotoken#notwork.org)
  2001-01-12: made bmbm module func.  bmbm return Tms array. 
  2001-01-10: added bmbm, Job and INSTALL.rb (gotoken#notwork.org)
  2000-04-00: report() prints tag before eval block (gotoken#notwork.org)
  2000-02-22: report(): measure -> Benchmark::measure (nakahiro#sarion.co.jp)
  2000-01-02: bug fix, documentation (gotoken#notwork.org)
  2000-01-01: measure can take a tag as opt. (nobu.nakada#nifty.ne.jp)
  2000-01-01: first release (gotoken#notwork.org)
=end

module Benchmark
  BENCHMARK_VERSION = "2002-04-25"

  if Process.respond_to? :times
    def Benchmark::times()
      Process::times()
    end
  else # for Ruby 1.6.x or earlier
    def Benchmark::times()
      Time::times()
    end
  end

  def benchmark(caption = "", label_width = nil, fmtstr = nil, *labels)
    sync = STDOUT.sync
    STDOUT.sync = true
    label_width ||= 0
    fmtstr ||= FMTSTR
    raise ArgumentError, "no block" unless iterator?
    print caption
    results = yield(Report.new(label_width, fmtstr))
    Array === results and results.grep(Tms).each {|t|
      print((labels.shift || t.label || "").ljust(label_width), 
	    t.format(fmtstr))
    }
    STDOUT.sync = sync
  end

  def bm(label_width = 0, *labels, &blk)
    benchmark(" "*label_width + CAPTION, label_width, FMTSTR, *labels, &blk)
  end

  def bmbm(width = 0, &blk)
    job = Job.new(width)
    yield(job)
    width = job.width
    sync = STDOUT.sync
    STDOUT.sync = true

    # rehearsal
    print "Rehearsal "
    puts '-'*(width+CAPTION.length - "Rehearsal ".length)
    list = []
    job.list.each{|label,item|
      print(label.ljust(width))
      res = Benchmark::measure(&item)
      print res.format()
      list.push res
    }
    sum = Tms.new; list.each{|i| sum += i}
    ets = sum.format("total: %tsec")
    printf("%s %s\n\n",
	   "-"*(width+CAPTION.length-ets.length-1), ets)
    
    # take
    print ' '*width, CAPTION
    list = []
    ary = []
    job.list.each{|label,item|
      GC::start
      print label.ljust(width)
      res = Benchmark::measure(&item)
      print res.format()
      ary.push res
      list.push [label, res]
    }

    STDOUT.sync = sync
    ary
  end

  def measure(label = "")
    t0, r0 = Benchmark.times, Time.now
    yield
    t1, r1 = Benchmark.times, Time.now
    Benchmark::Tms.new(t1.utime  - t0.utime, 
		       t1.stime  - t0.stime, 
		       t1.cutime - t0.cutime, 
		       t1.cstime - t0.cstime, 
		       r1.to_f - r0.to_f,
		       label)
  end

  def realtime(&blk)
    Benchmark::measure(&blk).real
  end

  class Job
    def initialize(width)
      @width = width
      @list = []
    end

    def item(label = "", &blk)
      raise ArgmentError, "no block" unless block_given?
      label.concat ' '
      w = label.length
      @width = w if @width < w
      @list.push [label, blk]
      self
    end

    alias report item
    attr_reader :list, :width
  end

  module_function :benchmark, :measure, :realtime, :bm, :bmbm

  class Report
    def initialize(width = 0, fmtstr = nil)
      @width, @fmtstr = width, fmtstr
    end

    def item(label = "", *fmt, &blk)
      print label.ljust(@width)
      res = Benchmark::measure(&blk)
      print res.format(@fmtstr, *fmt)
      res
    end

    alias report item
  end

  class Tms
    CAPTION = "      user     system      total        real\n"
    FMTSTR = "%10.6u %10.6y %10.6t %10.6r\n"

    attr_reader :utime, :stime, :cutime, :cstime, :real, :total, :label

    def initialize(u = 0.0, s = 0.0, cu = 0.0, cs = 0.0, real = 0.0, l = nil)
      @utime, @stime, @cutime, @cstime, @real, @label = u, s, cu, cs, real, l
      @total = @utime + @stime + @cutime + @cstime
    end

    def add(&blk)
      self + Benchmark::measure(&blk) 
    end

    def add!
      t = Benchmark::measure(&blk) 
      @utime  = utime + t.utime
      @stime  = stime + t.stime
      @cutime = cutime + t.cutime
      @cstime = cstime + t.cstime
      @real   = real + t.real
      self
    end

    def +(x); memberwise(:+, x) end
    def -(x); memberwise(:-, x) end
    def *(x); memberwise(:*, x) end
    def /(x); memberwise(:/, x) end

    def format(arg0 = nil, *args)
      fmtstr = (arg0 || FMTSTR).dup
      fmtstr.gsub!(/(%[-+\.\d]*)n/){"#{$1}s" % label}
      fmtstr.gsub!(/(%[-+\.\d]*)u/){"#{$1}f" % utime}
      fmtstr.gsub!(/(%[-+\.\d]*)y/){"#{$1}f" % stime}
      fmtstr.gsub!(/(%[-+\.\d]*)U/){"#{$1}f" % cutime}
      fmtstr.gsub!(/(%[-+\.\d]*)Y/){"#{$1}f" % cstime}
      fmtstr.gsub!(/(%[-+\.\d]*)t/){"#{$1}f" % total}
      fmtstr.gsub!(/(%[-+\.\d]*)r/){"(#{$1}f)" % real}
      arg0 ? Kernel::format(fmtstr, *args) : fmtstr
    end

    def to_s
      format
    end

    def to_a
      [@label, @utime, @stime, @cutime, @cstime, @real]
    end

    protected
    def memberwise(op, x)
      case x
      when Benchmark::Tms
	Benchmark::Tms.new(utime.__send__(op, x.utime),
			   stime.__send__(op, x.stime),
			   cutime.__send__(op, x.cutime),
			   cstime.__send__(op, x.cstime),
			   real.__send__(op, x.real)
			   )
      else
	Benchmark::Tms.new(utime.__send__(op, x),
			   stime.__send__(op, x),
			   cutime.__send__(op, x),
			   cstime.__send__(op, x),
			   real.__send__(op, x)
			   )
      end
    end
  end

  CAPTION = Benchmark::Tms::CAPTION
  FMTSTR = Benchmark::Tms::FMTSTR
end

if __FILE__ == $0
  include Benchmark

  n = ARGV[0].to_i.nonzero? || 50000
  puts %Q([#{n} times iterations of `a = "1"'])
  benchmark("       " + CAPTION, 7, FMTSTR) do |x|
    x.report("for:")   {for i in 1..n; a = "1"; end} # Benchmark::measure
    x.report("times:") {n.times do   ; a = "1"; end}
    x.report("upto:")  {1.upto(n) do ; a = "1"; end}
  end

  benchmark do
    [
      measure{for i in 1..n; a = "1"; end},  # Benchmark::measure
      measure{n.times do   ; a = "1"; end},
      measure{1.upto(n) do ; a = "1"; end}
    ]
  end
end
