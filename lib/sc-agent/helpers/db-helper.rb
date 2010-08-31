#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
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
require 'sc-agent/models/artifact'

module SteamCannon
  class DBHelper
    def initialize( name, options = {} )
      @log = options[:log] || Logger.new(STDOUT)

      @service = Service.create( :name => name )
    end

    def save_artifact( artifact )
      return false unless artifact.is_a?(Hash)

      artifact[:service] = @service

      begin
        return Artifact.create( artifact )
      rescue => e
        @log.error e.backtrace
        false
      end
    end

    def remove_artifact( artifact_id )
      a =  artifact( artifact_id )

      return false unless a

      begin
        a.destroy
        return true
      rescue => e
        @log.error e.backtrace
        false
      end
    end

    def artifacts
      begin
        return Artifact.all( :service => @service )
      rescue => e
        @log.error e.backtrace
        false
      end
    end

    def artifact( id )
      begin
        return Artifact.get( id )
      rescue => e
        @log.error e.backtrace
        false
      end
    end

    def save_event( operation, status, options = {})
      begin
        return Event.create( :operation => operation, :time => Time.now, :status => status, :service => @service, :msg => options[:msg], :parent => options[:parent] )
      rescue => e
        @log.error e.backtrace
        false
      end
    end
  end
end
