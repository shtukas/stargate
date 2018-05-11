#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeWhile(repositorylocation, queueuuid, xlambda: Element -> Boolean)
=end

# -------------------------------------------------------------------------------------

OpenProjects_PATH_TO_REPOSITORY = "/Galaxy/DataBank/Catalyst/Open-Projects"

# OpenProjects::updateObjectsCacheOnThisObject(object)
# OpenProjects::getCatalystObjects()

# OpenProjects::folderpaths(itemsfolderpath)
# OpenProjects::getuuidOrNull(folderpath)
# OpenProjects::folderpath2CatalystObjectOrNull(folderpath)
# OpenProjects::getCatalystObjectsFromDisk()


class OpenProjects

    @@objectsCache = []

    def self.setObjectsCache(envelop)
        @@objectsCache = envelop
        KeyValueStore::set(nil, "e16bf2b1-5e81-4b55-a676-d6ac068fb6b6", JSON.generate(envelop))
    end

    def self.updateObjectsCacheOnThisObject(object)
        thisOne, theOtherOnes = @@objectsCache.partition{|o| o["uuid"]==object["uuid"] }
        newObject = OpenProjects::folderpath2CatalystObjectOrNull(object["item-folderpath"])
        OpenProjects::setObjectsCache((theOtherOnes + [newObject]).compact)
    end

    def self.getCatalystObjects()
        @@objectsCache
    end

    def self.folderpaths(itemsfolderpath)
        Dir.entries(itemsfolderpath)
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{itemsfolderpath}/#{filename}" }
    end

    def self.getuuidOrNull(folderpath)
        return nil if !File.exist?(folderpath)
        if !File.exist?("#{folderpath}/.uuid") then
            File.open("#{folderpath}/.uuid", 'w'){|f| f.puts(SecureRandom.hex(4)) }
        end
        IO.read("#{folderpath}/.uuid").strip
    end

    def self.performObjectClosing(object)
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath targetFolder
        puts "source: #{object['item-folderpath']}"
        puts "target: #{targetFolder}"
        FileUtils.mkpath(targetFolder)
        LucilleCore::copyFileSystemLocation(object['item-folderpath'], targetFolder)
        LucilleCore::removeFileSystemLocation(object['item-folderpath'])
    end

    def self.folderpath2CatalystObjectOrNull(folderpath)
        uuid = OpenProjects::getuuidOrNull(folderpath)
        return nil if uuid.nil?
        folderProbeMetadata = FolderProbe::folderpath2metadata(folderpath)
        announce = "(open) project: " + folderProbeMetadata["announce"]
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        {
            "uuid" => uuid,
            "metric" => isRunning ? 2 : GenericTimeTracking::metric2(uuid, 0.1, 0.8, 1),
            "announce" => announce,
            "commands" => ( isRunning ? ["stop"] : ["start"] ) + ["completed", "folder"],
            "default-expression" => isRunning ? "" : "start",
            "command-interpreter" => lambda{|object, command| OpenProjects::objectCommandHandler(object, command) },
            "item-folder-probe-metadata" => folderProbeMetadata,
            "item-folderpath" => folderpath
        }
    end

    def self.getCatalystObjectsFromDisk()
        OpenProjects::folderpaths(OpenProjects_PATH_TO_REPOSITORY)
            .map{|folderpath| OpenProjects::folderpath2CatalystObjectOrNull(folderpath) }
            .compact
    end

    def self.objectCommandHandler(object, command)
        if command=='start' then
            metadata = object["item-folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
            GenericTimeTracking::start(object["uuid"])
            OpenProjects::updateObjectsCacheOnThisObject(object)
        end
        if command=='stop' then
            GenericTimeTracking::stop(object["uuid"])
            OpenProjects::updateObjectsCacheOnThisObject(object)
        end
        if command=="completed" then
            GenericTimeTracking::stop(object["uuid"])
            OpenProjects::performObjectClosing(object)
            OpenProjects::updateObjectsCacheOnThisObject(object)
        end
        if command=="folder" then
            system("open '#{object["item-folderpath"]}'")
        end
    end
end

OpenProjects::setObjectsCache(
    JSON.parse(KeyValueStore::getOrDefaultValue(nil, "e16bf2b1-5e81-4b55-a676-d6ac068fb6b6", "[]"))
    .map{|object|
        object['command-interpreter'] = lambda{|object, command| OpenProjects::objectCommandHandler(object, command) }
        object
    }
)

Thread.new {
    loop {
        OpenProjects::setObjectsCache(OpenProjects::getCatalystObjectsFromDisk())
        sleep 73
    }
}