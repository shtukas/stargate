#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

# -------------------------------------------------------------------------------------

$ninja_packet = nil

class NSXAgentTheBridge

    # NSXAgentTheBridge::agentuuid()
    def self.agentuuid()
        "d2422ba0-88e9-4abb-9ab9-6d609015268f"
    end

    # NSXAgentTheBridge::getAgentsFilepaths()
    def self.getAgentsFilepaths()
        IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/TheBridge/filepaths.txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size>0 }
    end

    # NSXAgentTheBridge::getObjects()
    def self.getObjects()
        if NSXMiscUtils::isLucille18() then
            NSXAgentTheBridge::getAgentsFilepaths().map{|filepath| JSON.parse(`#{filepath}`) }.flatten
        else
            []
        end
    end

    def self.processObjectAndCommand(object, command)
        system(object["commandToShellInvocation"][command]) # With great powers come great responsibilities
    end
end

