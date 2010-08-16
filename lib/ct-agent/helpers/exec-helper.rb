# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'logger'
require 'rubygems'
require 'open4'

class ExecHelper
  def initialize( options = {} )
    @log = options[:log] || Logger.new(STDOUT)
  end

  def execute( command )
    @log.debug "Executing command: '#{command}'"

    begin
      Open4::popen4( command ) do |pid, stdin, stdout, stderr|
        threads = []

        threads << Thread.new(stdout) do |input_str|
          input_str.each do |l|
            @log.debug l.chomp.strip
          end
        end

        threads << Thread.new(stderr) do |input_str|
          input_str.each do |l|
            @log.debug l.chomp.strip
          end
        end
        threads.each{|t|t.join}
      end
    rescue => e
      @log.error e.backtrace.join($/)
      @log.error "An error occurred while executing command: '#{command}'"
      raise "An error occurred while executing command: '#{command}'"
    end
  end
end
