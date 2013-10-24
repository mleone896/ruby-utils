#!/usr/bin/env ruby


require 'rubygems'
require 'optparse'
require 'pp'
require 'ostruct'
require 'rye'
require 'highline/import'

class ParseArgs
    def self.parse(args)
        options = OpenStruct.new
        options.server = []
        opt_parser = OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename($0)} OPTIONS"
          opt.separator ""
          opt.separator "OPTIONS"
          opt.on("-S", "--server SERVER ", Array,  "which facter fact you would like to use") do |s|
            options.server << s
          end
          opt.on("-h", "--help", "help") do
            puts opt_parser
            exit
          end
          opt.on("-T", "--path DIRECTORY", "Path on remote server")  do |t|
              options.path = t
          end
          opt.on("-F", "--file FILE", "filename to be moved") do |f|
              options.file = f
          end
          opt.on("--flow upload/download", "Which way the file is going") do |flow|
              options.flow = flow
          end
          opt.on("-b", "--batch BATCHMODE", "Create a list of servers from a file") do |batch|
              options.batch = batch
           end
          opt.on("-P", "--pasword", "Your ssh password") do
              options.password = ask("Enter your password:  ") { |q| q.echo = "*" }
          end
        end
       opt_parser.parse!(args)
       options
    end # end parse()
end # close class


class FileOperations < Rye::Box
  attr_accessor :file, :path
  def initalize(file, path)
      @file = file
      @path = path
  end
  def file_upload(file, path)
     $rset.file_upload file, path
  end

  def file_download(file, path)
      puts $rset.file_download "#{path}/#{file}", file
  end
  def pinfo(msg)
    direction, progress, junk, is_done = *msg.tr('[]','').split(' ')
    name, bytes_sent, bytes_total, junk = *progress.tr('/',' ').split(' ')
    # ... where all dreams come true ...
    super # call the original Rye::Box#pinfo method
  end
end

#end

options = ParseArgs.parse(ARGV)
fileoperators = FileOperations.new
password = options.password

# grab the hosts in question from command line args
  if options.batch.to_s == "true"
     hostfile = ask("where is the file containing hosts ?:  ") { |q| q.echo = true }
     hosts = IO.readlines(hostfile)
     hosts.map! {|x| x.chomp}
  else
    hosts = options.server
  end
$rset = Rye::Set.new "setname", :password_prompt => false, :user => "mleone", \
    :parallel => false, :password => "#{password}", :parallel => true, :info => true
$rset.add_boxes hosts


 if !options.path.nil? and !options.file.nil? and options.flow == "upload"
   fileoperators.file_upload(options.file, options.path)
 end

 if !options.path.nil? and !options.file.nil? and options.flow == "download"
     fileoperators.file_download(options.file, options.path)
 end



