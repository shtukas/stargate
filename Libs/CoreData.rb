
# encoding: UTF-8

class CoreData

    # CoreData::coreDataReferenceTypes()
    def self.coreDataReferenceTypes()
        ["text", "url", "aion point", "open cycle", "unique string", "Dx8Unit"]
    end

    # CoreData::interactivelySelectCoreDataReferenceType()
    def self.interactivelySelectCoreDataReferenceType()
        types = CoreData::coreDataReferenceTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("coredata reference type", types)
    end

    # CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) # payload string
    def self.interactivelyMakeNewReferenceStringOrNull(uuid)
        # This function is called during the making of a new node (or when we are issuing a new payload of an existing node)
        # It does stuff and returns a payload string or null
        referencetype = CoreData::interactivelySelectCoreDataReferenceType()
        if referencetype.nil? then
            return "null"
        end
        if referencetype == "text" then
            text = CommonUtils::editTextSynchronously("")
            nhash = Blades::putDatablob2(uuid, text)
            return "text:#{nhash}"
        end
        if referencetype == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            nhash = Blades::putDatablob2(uuid, url)
            return "url:#{nhash}"
        end
        if referencetype == "aion point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash = AionCore::commitLocationReturnHash(BladeElizabeth.new(uuid), location)
            return "aion-point:#{nhash}" 
        end
        if referencetype == "open cycle" then
            fname = LucilleCore::askQuestionAnswerAsString("OpenCycle directory name: ")
            if !fname.start_with?("20") then
                fname = "#{CommonUtils::today()} #{fname}"
            end
            folderpath = "#{Config::pathToGalaxy()}/OpenCycles/#{fname}"
            if !File.exist?(folderpath) then
                FileUtils.mkdir(folderpath)
            end
            return "open-cycle:#{fname}"
        end
        if referencetype == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return "unique-string:#{uniquestring}"
        end
        if referencetype == "Dx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("Dx8Unit Id: ")
            return "Dx8UnitId:#{unitId}"
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) unsupported core data reference type: #{referencetype}"
    end

    # CoreData::referenceStringToSuffixString(referenceString)
    def self.referenceStringToSuffixString(referenceString)
        if referenceString.nil? then
            return ""
        end
        if referenceString == "null" then
            return ""
        end
        if referenceString.start_with?("text") then
            return " (text)"
        end
        if referenceString.start_with?("url") then
            return " (url)"
        end
        if referenceString.start_with?("aion-point") then
            return " (aion point)"
        end
        if referenceString.start_with?("open-cycle") then
            return " (open-cycle)"
        end
        if referenceString.start_with?("unique-string") then
            str = referenceString.split(":")[1]
            return " (unique string: #{str})"
        end
        if referenceString.start_with?("Dx8UnitId") then
            return " (Dx8Unit)"
        end
        raise "CoreData, I do not know how to string '#{referenceString}'"
    end

    # CoreData::itemToSuffixString(item)
    def self.itemToSuffixString(item)
        CoreData::referenceStringToSuffixString(item["field11"])
    end

    # CoreData::access(uuid, referenceString)
    def self.access(uuid, referenceString)
        if referenceString.nil? then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString == "null" then
            puts "Accessing null reference string. Nothing to do."
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = Blades::getDatablobOrNull2(uuid, nhash)
            puts "--------------------------------------------------------------"
            puts text
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("url") then
            nhash = referenceString.split(":")[1]
            url = Blades::getDatablobOrNull2(uuid, nhash)
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            puts "CoreData, accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "aion-point-#{exportId}"
            exportFolder = "#{Config::pathToDesktop()}/#{exportFoldername}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(BladeElizabeth.new(uuid), nhash, exportFolder)
            LucilleCore::pressEnterToContinue()
            return
        end
        if referenceString.start_with?("open-cycle") then
            fname = referenceString.split(":")[1]
            directoryFilepath = "#{Config::pathToGalaxy()}/OpenCycles/#{fname}"
            system("open '#{directoryFilepath}'")
            return
        end
        if referenceString.start_with?("unique-string") then
            uniquestring = referenceString.split(":")[1]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            unitId = referenceString.split(":")[1]
            Dx8Units::access(unitId)
            return
        end
        raise "CoreData, I do not know how to access '#{referenceString}'"
    end

    # CoreData::fsck(uuid, referenceString)
    def self.fsck(uuid, referenceString)
        puts "CoreData::fsck(uuid: #{uuid}, referenceString: #{referenceString})"
        if referenceString.nil? then
            return
        end
        if referenceString == "null" then
            return
        end
        if referenceString.start_with?("text") then
            nhash = referenceString.split(":")[1]
            text = Blades::getDatablobOrNull2(uuid, nhash)
            if text.nil? then
                raise "CoreData::fsck: could not extract text for uuid: #{uuid}, referenceString: #{referenceString}"
            end
            return
        end
        if referenceString.start_with?("url") then
            return
        end
        if referenceString.start_with?("aion-point") then
            nhash = referenceString.split(":")[1]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(BladeElizabeth.new(uuid), nhash)
            return
        end
        if referenceString.start_with?("open-cycle") then
            return
        end
        if referenceString.start_with?("unique-string") then
            return
        end
        if referenceString.start_with?("Dx8UnitId") then
            return
        end
        raise "CoreData, I do not know how to access '#{referenceString}'"
    end
end
