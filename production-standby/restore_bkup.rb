#!/usr/bin/env ruby
#
require 'logger'
require 'fileutils'

#create logger object
FileUtils.touch('/var/lib/pgsql/data/restore_bkup.log')
logger = Logger.new('/var/lib/pgsql/data/restore_bkup.log')

logger.formatter = proc do |severity,time,progname,msg|
  "#{time} #{severity}--- #{msg}\n"
end

bkup_file = 'base.tar.gz'
bkup_dest = '/var/lib/pgsql/backups/'

def check_id
  id = %x(echo $USER)
  return id
end

def copy_bkup(bkup_file,bkup_dest,logger)
  if File.exist?("/mnt/db_bkup/#{bkup_file}")
    begin
      FileUtils.cp("/mnt/db_bkup/#{bkup_file}","#{bkup_dest}")
    rescue => msg
      logger.error("Unable to copy #{bkup_file} to #{bkup_dest}\n#{msg}")
      Process.exit(1)
    end
  else
    logger.error("No backup file available to copy!")
    Process.exit(1)
  end
end

def uncompress_bkup(bkup_file,bkup_dest,logger)
  begin
    %x(cd #{bkup_dest})
    FileUtils.mkdir("#{bkup_dest}/data")
    FileUtils.chmod(0700,"#{bkup_dest}/data")
    output = %x(tar xf #{bkup_dest}/#{bkup_file} -C #{bkup_dest}/data/)
    raise "Issue uncompressing backup\n#{output}" if $?.exitstatus != 0
  rescue => msg
    logger.error(msg)
    cleanup(bkup_dest,'failure')
    Process.exit(1)
  end
end

def rsync_files(bkup_dest,logger)
  begin
    output = %x(rsync -cpa --inplace --exclude=*pg_xlog* #{bkup_dest}/data/ /var/lib/pgsql/data/)
    if $?.exitstatus != 0
      raise "Unable to sync backup data to /var/lib/pgsql/data/\n#{output}"
    end
  rescue => msg
    logger.error(msg)
    cleanup(bkup_dest,'failure')
    Process.exit(1)
  end
end

def cleanup(bkup_dest,type)
  if type == 'failure'
    puts "Failures detected, running cleanup. Consult the log."
  else
    puts "Cleaning up #{bkup_dest}..."
  end
  %x(rm -rf #{bkup_dest}/*)  
end

######Imperative Execution Domain#########
puts "See /var/lib/pgsql/data/restore_bkup.log for run details..."

id = check_id.strip
if id != 'postgres'
  msg = "Must run as postgres"
  logger.error(msg)
  puts msg
  Process.exit(1)
end

#Check for a prior restore - we do not want to restore twice on accident.
if File.exists?('/var/lib/pgsql/data/.restored_from_bkup')
  msg = <<-msg_txt
   ISSUE: a prior restore has been detected!
   In order to override this check, please remove 
   the /var/lib/pgsql/data/.restored_from_bkup file.
   Exitting...
  msg_txt
  logger.error(msg)
  puts msg
  Process.exit(1)
end


copy_bkup(bkup_file,bkup_dest,logger)
logger.info("Copied #{bkup_file} to #{bkup_dest} successfuly.")

uncompress_bkup(bkup_file,bkup_dest,logger)
logger.info("Uncompressed #{bkup_file} to #{bkup_dest}/data successfully.")

rsync_files(bkup_dest,logger)
logger.info("Successfully restored data from backup.")

puts "Successfully restored backup..."
FileUtils.touch('/var/lib/pgsql/data/.restored_from_bkup')
cleanup(bkup_dest,'success')
