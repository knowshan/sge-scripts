#!/usr/bin/env ruby

# == Synopsis 
#   Not Available
#
# == Examples
# ./accounting.rb -i /opt/gridengine/default/common/accounting -o testofile -u pavgi -s 3d
# ./accounting.rb -ipfile /opt/gridengine/default/common/accounting -opfile testofile --user pavgi --since 3d  
#
# == Usage 
#   accounting.rb [options]
#   For help use: accounting.rb -h
#   See Examples ^^
# 
# == Author
#   Shantanu Pavgi, knowshantanu@gmail.com  
# == Credits
#   Useful post for writing command-line application skeleton - http://blog.toddwerth.com/entries/5 
# == Depenedcies - included as standard Ruby lib; no external gems/lib required:  
#   'optparse'
#   'ostruct'
# == TODO
#   Improve skeleton and instance variable usage
#   Setting stdout as a default during initialization 
# 
# Example line from accounting file which needs to be parsed: 
# compute.q:compute-0-6.local:pavgi:pavgi:galaxy_2503.sh:8070699:sge:0:1311868550:1311868559:1311875460:100:138:6901:0.000000:0.001999:0.000000:0:0:0:0:574:0:0:0.000000:0:0:0:0:43:2:NONE:defaultdepartment:NONE:1:0:6888.600000:511.570799:9.135190:-u pavgi -l h_rt=7200,h_vmem=2G,s_rt=6900,virtual_free=2G:0.000000:NONE:145149952.000000:0:0

# 0 : queue
# 1 : compute node
# 2 : group
# 3 : user
# 4 : job script name
# 5 : job number
# 6 : account sge
# 7 : priority
# 8 : submission time
# 9 : start time
# 10: end time
# 11: failed - for sge killed run-time jobs 100, sge killed memory limit jobs 100, job fails for some reason1 non-zero
# 12: exit-status - for sge killed run-time jobs 138, sge killed memory limit jobs 137, job fails for some reason1 19
# 13
# ..
# ..

require 'optparse'
require 'ostruct'
require 'time'

class JobSearch
  VERSION="1.0.0"

  # Initialize/instantiate new JobSearch object 
  attr_reader :options
  def initialize(arguments)
    @arguments = arguments
    # set default options 
    @options = OpenStruct.new
    @options.help = false
    @options.verbose = false
    @options.ipfile = "#{ENV['SGE_ROOT']}/#{ENV['SGE_CELL']}/common/accounting"
    @options.user = ENV['USER']
    @options.since = "1d"
  end

  def run
    # parsed_options 
    if parsed_options? 
      # process_options # should process_option be called here or from parsed_options??
      # output_options
      # process_command performs the real job - parsing SGE accounting file
      process_command
    else
      puts "Unknown Error..."
      exit 99
    end
  end
  
  protected 
  def parsed_options?
    # define options
    since_regex = /\d+[m|h|d]/
    @optionparser_obj = OptionParser.new do |opts|
      opts.banner = "#{$0} OPTIONS"
      opts.on('-h', '--help', "Display help") { @options.help = true }
      opts.on('-v', '--verbose', "Verbose mode") { @options.verbose = true }
      opts.on('-i', '--ipfile IFILE', "SGE Accounting file    (Optional, Default: #{ENV['SGE_ROOT']}/#{ENV['SGE_CELL']}/common/accounting)") { |a| @options.ipfile = a }
      opts.on('-o', '--opfile OFILE', "Output file    (Optional, Default: STDOUT)") { |a| @options.opfile = a }
      opts.on('-u', '--user USER', "Usernme filter    (Optional, Default: #{ENV['USER']})") { |a| @options.user = a }
      opts.on('-s', '--since SINCE', since_regex, "Go back in history until N[m|h|d]    (Optional, Default: 1d)    (m=Minutes, h=Hours, d=Days)") { |a| @options.since = a }
      opts.separator ""
    end
    # Parse @options passed 
    begin 
      @optionparser_obj.parse!(@arguments)
    rescue OptionParser::InvalidOption => e
      puts e
      exit 1
    rescue OptionParser::MissingArgument => e
      puts e 
      exit 1
    rescue OptionParser::InvalidArgument => e
      puts e 
      exit 1
    end
    process_options
    true
  end
  
  # print output options 
  def output_options
    @options.marshal_dump.each do |name,value|
      puts "#{name} = #{value} "
    end
  end
  
  # Process options and assign them to specific variables as needed
  def process_options
    output_help if @options.help
    @afilename = @options.ipfile 
    @ofilename = @options.opfile 
    @user = @options.user
    # convert 'since' time to seconds
    since = @options.since 
    case since
    when /\d+m/
      @seconds = since.to_i * 60
    when /\d+h/
      @seconds = since.to_i * 60 * 60
    when /\d+d/
      @seconds = since.to_i * 24 * 60 * 60   
    else
      puts "Unexpected pattern encountered in '--since' option!"
      exit 99
    end
  end
  
  # Real command - where accounting file is parsed 
  def process_command
    puts "# #{$0} #{@options.to_s}" if @options.verbose
    # Get current time in epochs
    time = Time.now
    epochs = time.gmtime.to_i
    # Subtract seconds(obtained from minutes user ip) to go back in accounting file
    epochs = epochs - @seconds.to_i
    # Output file  - set to STDOUT if @options.opfile not specified
    if @ofilename 
      ofile = File.open(@ofilename, "w") 
    else
      ofile = STDOUT
    end
    ofile << "# Failed jobs for user #{@user} since last #{@options.since}\n" if @options.verbose
    ofile << "# SGE Job ID,Job script name,Requested Memory,Used Memory,Requested run-time,Actual walltime\n" if @options.verbose
    count_failed_jobs = 0
    File.foreach(@afilename) do |aline| 
      # Select lines that match following criteria: 
      ## specified-username
      ## && (completed/end-time in last n minutes #{epochs})
      ## && (failed status is non-zero || exit status is non-zero)
      if aline !~ /#/
        aarray = aline.split(":")
        wallclock = aarray[10].to_i - aarray[9].to_i
        s_rt = aarray[39].slice(/(s_rt=)([\d]+)/,2).to_i # get requested s_rt
        h_rt = aarray[39].slice(/(h_rt=)([\d]+)/,2).to_i # get requested h_rt
        h_vmem = aarray[39].slice(/(h_vmem=)([[:alnum:]]+)/,2) # get requested h_vmem
        failure = wallclock.between?(s_rt,h_rt+2) ? "Reached max. run-time limit #{seconds_to_units(h_rt)}" : "Reached max. memory limit #{h_vmem}"
        if aarray[3]== @user && (aarray[10].to_i>=epochs) && (aarray[11]!='0' || aarray[12]!='0')
          #ofile << "#{aarray[5]} #{epochs} #{aarray[10]} #{time}\n"
          ofile << "#{aarray[5]},#{aarray[4]},#{h_vmem},#{aarray[42]},#{h_rt},#{wallclock},#{failure}\n"
          count_failed_jobs = count_failed_jobs + 1 
        end
      end
    end
    ofile << "# #{count_failed_jobs} jobs failed for #{@user} in last #{@options.since}\n" if @options.verbose
    ofile.close
    # Close output file 
  end

  # from http://stackoverflow.com/a/6552812
  def seconds_to_units(seconds)
    '%d hours %d minutes %d seconds' %
    # the .reverse lets us put the larger units first for readability
    [60,60].reverse.inject([seconds]) {|result, unitsize|
      result[0,0] = result.shift.divmod(unitsize)
      result
    }
  end
  
  def output_help
    puts "HELP:"
    puts @optionparser_obj
    exit
  end
end

job = JobSearch.new(ARGV)
job.run
