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

      option :connection_draining_timeout,
            :long => '--connection-draining-timeout Timeout',
            :description => 'Max time (in seconds) to keep existing conns open before deregistering instances.',
            :default => 300,
            :proc => Proc.new { |i| i.to_i }

      option :enable_cross_zone_balancing,
            :long => '--enable-cross-zone-balancing',
            :description => 'Enable cross zone load balancing',
            :boolean => true

      option :connection_idle_timeout,
            :long => '--connection-idle-timeout Timeout',
            :description => 'time (in seconds) the connection is allowed to be idle before it is closed.',
            :default => 60,
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
        attrs["ConnectionDraining"] = {
            "Enabled" => true,
            "Timeout" => config[:connection_draining_timeout]
        }  if config[:enable_connection_draining]

        attrs["CrossZoneLoadBalancing"] = {"Enabled" => true} if config[:enable_cross_zone_balancing]
        attrs["ConnectionSettings"] = {"IdleTimeout" => config[:connection_idle_timeout]} if ! config[:connection_idle_timeout].nil?

        ui.info("Resolved attributes: #{attrs}")
        attrs
      end

      def validate!
        super

        unless @name_args.size == 1
          ui.error('Please specify the ELB ID')
          exit 1
        end

        if config[:availability_zones].empty?
          ui.error("You have not provided a valid availability zone value. (-Z parameter)")
          exit 1
        end
      end
    end
  end
end
