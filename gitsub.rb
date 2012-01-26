#!/usr/bin/env ruby
require 'open3'

# README: I use it to make sure my SGE job script is up-to-date 
# in local git repository before submitting it to the cluster. 
# Also adds qsub stdout (job number, if successful) and latest git 
# sha1 to JobInfo.txt file (hard-coded). 
# TODO: A Lot! 
# Usage gitsub.rb <job-script>

# Basic check for args - will replace by optparse later
if ARGV.length != 1
  puts "Usage: #{$0} <job-script-name>"
  puts "qsub-s given <job-script-name> only if it is up-to-date with latest git repo commit"
  exit 99
end

js_name = ARGV[0]

# Start-Method checks if file exists in Git repo
def file_in_repo?(js_name)
  # Start-Open3
  Open3.popen3("git ls-files #{js_name} --error-unmatch") do |stdin, stdout, stderr|
    # Start-If: Check if job script is committed in git repo 
    if stderr.read.empty?
      return true
    else
      puts "Please commit #{js_name} to the repository before qsub-ing it!"
      return false
    end
    # End-If Check if job script is committed in git repo
  end
end
# End-Method checks if file exists in Git repo

# Start-Method checks if file in CWD is unchanged since last commit
def file_unchanged?(js_name)
  # Start-Open3
  Open3.popen3("git status --short #{js_name}") do |stdin, stdout, stderr|
    # Start-If: Check if job script in working dir is modified since last check-in
    if stdout.read.empty? 
      return true
    else 
      puts "#{js_name} modified since last commit. Please commit changes to the repo and #{$0} again!"
      return false
    end
    # End-If: Check if job script in working dir is modified since last check-in
  end
  # End-Open3
end
# End-Method checks if file in CWD is unchanged since last commit

# Start-Method return latest commit sha1 
def last_commit(js_name)
  sha1 = `git log --pretty=%H -1 #{js_name}`  
end
# End-Method return latest commit sha1 

# Start-If Check if job script is commited in git repo
if file_in_repo?(js_name)
  # Start-If Check if file is unchanged since last commit
  if file_unchanged?(js_name)
    qsub_op = `qsub #{js_name}` # Submit job
    latest_sha1 = last_commit(js_name) # Get last sha1 from git repo
    # Start-IO: Write job number and latest sha1 to a file
    File.open('JobInfo.txt','a') do |f|
      f.write("#{qsub_op.chomp}, #{latest_sha1} \n")
    end
    # End-IO Write job number and latest sha1 to a file
  end
  # End-If Check if file is unchanged since last commit  
end
# End-If Check if job script is commited in git repo
