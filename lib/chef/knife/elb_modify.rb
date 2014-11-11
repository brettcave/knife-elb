# Author:: Brett Cave (<brett@cave.za.net>)
# Copyright:: Copyright (c) 2014 Brett Cave
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/knife'
require 'chef/knife/elb_base'

class Chef
  class Knife
    class ElbModify < Knife
      include Chef::Knife::ElbBase

      banner 'knife elb modify ELB (options)'

      option :enable_connection_draining,
            :long => '--enable-connection-draining',
            :description => 'Enable connection draining',
            :boolean => true

      option :disable_connection_draining,
             :long => '--disable-connection-draining',
             :description => 'Disable connection draining',
             :boolean => true

      option :connection_draining_timeout,
            :long => '--connection-draining-timeout Timeout',
            :description => 'Max time (in seconds) to keep existing conns open before deregistering instances.',
            :default => 300,
            :proc => Proc.new { |i| i.to_i }

      option :enable_cross_zone_balancing,
            :long => '--enable-cross-zone-balancing',
            :description => 'Enable cross zone load balancing',
            :boolean => true

      option :disable_cross_zone_balancing,
             :long => '--disable-cross-zone-balancing',
             :description => 'Disable cross zone load balancing',
             :boolean => true

      option :connection_idle_timeout,
            :long => '--connection-idle-timeout Timeout',
            :description => 'time (in seconds) the connection is allowed to be idle before it is closed.',
            :proc => Proc.new { |i| i.to_i }

      def run
        validate!

        response = connection.modify_load_balancer_attributes(
            @name_args.first,
            build_attributes
        )

        ui.output(Chef::JSONCompat.from_json(response.data[:body].to_json))
      end

      private

      def build_attributes
        attrs = {}

        enable_connection_draining = config[:disable_connection_draining] ? false : config[:enable_connection_draining]
        attrs["ConnectionDraining"] = {
            "Enabled" => enable_connection_draining,
            "Timeout" => config[:connection_draining_timeout]
        } unless enable_connection_draining.nil?

        enable_cross_zone_balancing = config[:disable_cross_zone_balancing] ? false : config[:enable_cross_zone_balancing]
        attrs["CrossZoneLoadBalancing"] = {"Enabled" => enable_cross_zone_balancing} unless enable_cross_zone_balancing.nil?

        attrs["ConnectionSettings"] = {"IdleTimeout" => config[:connection_idle_timeout]} unless config[:connection_idle_timeout].nil?

        attrs
      end

      def validate!
        super

        unless @name_args.size == 1
          ui.error('Please specify the ELB ID')
          exit 1
        end

        if (config[:enable_connection_draining] && config[:disable_connection_draining]) || (config[:enable_cross_zone_balancing] && config[:disable_cross_zone_balancing])
          ui.error('Conflicting options. Please check that only 1 of --enable / --disable options are specified.')
          exit 1
        end
      end
    end
  end
end
