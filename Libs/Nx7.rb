
# encoding: UTF-8

class Nx7

    # ------------------------------------------------
    # Basic IO

    # Nx7::twoFilepaths(uuid)
    def self.twoFilepaths(uuid)
        {
            "standard" => "#{Config::pathToDataCenter()}/Nx7/#{uuid}.Nx5",
            "desktop"  => "#{Config::pathToDesktop()}/#{uuid}.Nx5"
        }
    end

    # Nx7::filepath(uuid)
    def self.filepath(uuid)
        filepaths = Nx7::twoFilepaths(uuid)
        filepaths.values.each{|filepath|
            if File.exists?(filepath) then
                return filepath
            end
        }
        filepaths["standard"]
    end

    # Nx7::newFilepathOnDesktop(uuid)
    def self.newFilepathOnDesktop(uuid)
        filepath = Nx7::twoFilepaths(uuid)["desktop"]
        Nx5::issueNewFileAtFilepath(filepath, uuid)
        filepath
    end

    # Nx7::archiveFileFromDesktopToDataCenter(uuid)
    def self.archiveFileFromDesktopToDataCenter(uuid)
        filepaths = Nx7::twoFilepaths(uuid)
        if File.exists?(filepaths["desktop"]) then
            FileUtils.mv(filepaths["desktop"], filepaths["standard"])
        end
    end

    # Nx7::filepathForExistingItemOrError(uuid)
    def self.filepathForExistingItemOrError(uuid)
        filepath = Nx7::filepath(uuid)
        if File.exists?(filepath) then
            return filepath
        end
        raise "(error: 0b09f017-0423-4eb8-ac46-4a8966ad4ca6) could not determine presumably existing filepath for uuid: #{uuid}"
    end

    # Nx7::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Nx7")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
            .each{|filepath|
                Nx5SyncthingConflictResolution::probeAndRepairIfRelevant(filepath)
            }

        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Nx7")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # Nx7::itemsEnumerator()
    def self.itemsEnumerator()
        Enumerator.new do |items|
            Nx7::filepaths().each{|filepath|
                items << Nx5Ext::readFileAsAttributesOfObject(filepath)
            }
        end
    end

    # Nx7::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        filepath = Nx7::filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Nx7::commit(object)
    def self.commit(object)
        FileSystemCheck::fsck_MikuTypedItem(object, false)
        filepath = Nx7::filepathForExistingItemOrError(object["uuid"])
        object.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # Nx7::destroy(uuid)
    def self.destroy(uuid)
        filepath = Nx7::filepath(uuid)
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # ------------------------------------------------
    # Elizabeth

    # Nx7::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Nx7::filepathForExistingItemOrError(uuid)
        ElizabethNx5.new(filepath)
    end

    # Nx7::operatorForItem(item)
    def self.operatorForItem(item)
        Nx7::operatorForUUID(item["uuid"])
    end

    # ------------------------------------------------
    # Makers

    # Nx7::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
        puts JSON.pretty_generate(nx7Payload)
        FileSystemCheck::fsck_Nx7Payload(operator, nx7Payload, true)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_f,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "comments"      => [],
            "parentsuuids"  => [],
            "relatedsuuids" => [],
        }
        FileSystemCheck::fsck_Nx7(operator, item, true)
        Nx7::commit(item)
        Nx7::archiveFileFromDesktopToDataCenter(uuid)
        Search::nyxNx20sComputeAndCacheUpdate()
        item
    end

    # Nx7::issueNewUsingFile(filepath)
    def self.issueNewUsingFile(filepath)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        description = File.basename(filepath)
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::makeDataFile(operator, filepath)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => []
        }
        Nx7::commit(item)
        Nx7::archiveFileFromDesktopToDataCenter(uuid)
        item
    end

    # Nx7::issueNewUsingLocation(location)
    def self.issueNewUsingLocation(location)
        if File.file?(location) then
            return Nx7::issueNewUsingFile(location)
        end
        uuid = SecureRandom.uuid
        operator = Nx7::operatorForUUID(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        nx7filepath = Nx7::newFilepathOnDesktop(uuid)
        operator = ElizabethNx5.new(nx7filepath)
        nx7Payload = Nx7Payloads::makeDataNxDirectoryContents(operator, location)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "Nx7",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "nx7Payload"    => nx7Payload,
            "parentsuuids"  => [],
            "relatedsuuids" => []
        }
        Nx7::commit(item)
        Nx7::archiveFileFromDesktopToDataCenter(uuid)
        item
    end

    # ------------------------------------------------
    # Data

    # Nx7::toString(item)
    def self.toString(item)
        "(Nx7) (#{item["nx7Payload"]["type"]}) #{item["description"]}"
    end

    # Nx7::toStringForNx7Landing(item)
    def self.toStringForNx7Landing(item)
        "(node) #{item["description"]}"
    end

    # Nx7::parents(item)
    def self.parents(item)
        item["parentsuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # Nx7::relateds(item)
    def self.relateds(item)
        item["relatedsuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # Nx7::children(item)
    def self.children(item)
        return [] if item["nx7Payload"]["type"] == "Data"
        item["nx7Payload"]["childrenuuids"]
            .map{|objectuuid| Nx7::itemOrNull(objectuuid) }
            .compact
    end

    # ------------------------------------------------
    # Network Topology

    # Nx7::relate(item1, item2)
    def self.relate(item1, item2)
        item1["relatedsuuids"] = (item1["relatedsuuids"] + [item2["uuid"]]).uniq
        Nx7::commit(item1)
        item2["relatedsuuids"] = (item2["relatedsuuids"] + [item1["uuid"]]).uniq
        Nx7::commit(item2)
    end

    # Nx7::arrow(item1, item2)
    def self.arrow(item1, item2)
        # Type Data doesn't get children
        if item1["nx7Payload"]["type"] == "Data" then
            puts "We have a policy not to set a data carrier as parent"
            LucilleCore::pressEnterToContinue()
            return
        end
        item1["nx7Payload"]["childrenuuids"] = (item1["nx7Payload"]["childrenuuids"] + [item2["uuid"]]).uniq
        Nx7::commit(item1)
        item2["parentsuuids"] = (item2["parentsuuids"] + [item1["uuid"]]).uniq
        Nx7::commit(item2)
    end

    # Nx7::detach(item1, item2)
    def self.detach(item1, item2)
        item1["parentsuuids"].delete(item2["uuid"])
        item1["relatedsuuids"].delete(item2["uuid"])
        if item1["nx7Payload"]["type"] == "Data" then
            item1["nx7Payload"]["childrenuuids"].delete(item2["uuid"])
        else
            item1["childrenuuids"].delete(item2["uuid"])
        end
        Nx7::commit(item1)

        item2["parentsuuids"].delete(item1["uuid"])
        item2["relatedsuuids"].delete(item1["uuid"])
        if item2["nx7Payload"]["type"] == "Data" then
            item2["nx7Payload"]["childrenuuids"].delete(item1["uuid"])
        else
            item2["childrenuuids"].delete(item1["uuid"])
        end
        Nx7::commit(item2)
    end

    # ------------------------------------------------
    # Operations

    # Nx7::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = Nx7::filepathForExistingItemOrError(uuid)
        ElizabethNx5.new(filepath)
    end

    # Nx7::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: 520a0efa-48a1-4b81-82fb-f61760af7329)" if item["mikuType"] != "Nx7"
        Nx7::getElizabethOperatorForUUID(item["uuid"])
    end

    # Nx7::access(item)
    def self.access(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            GridState::access(operator, state)
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            puts "This is a navigation node, there isn't an access per se."
            LucilleCore::pressEnterToContinue()
        end
    end

    # Nx7::edit(item)
    def self.edit(item)

        nx7Payload = item["nx7Payload"]

        if nx7Payload["type"] == "Data" then
            state = nx7Payload["state"]
            operator = Nx7::getElizabethOperatorForItem(item)
            state2 = GridState::edit(operator, state)
            if state2 then
                nx7Payload["state"] = state2
                item["nx7Payload"] = nx7Payload
                Nx7::commit(item)
                Nx7::reExportAllItemCurrentlyExportedLocations(item)
            end
        end

        if Nx7Payloads::navigationTypes().include?(nx7Payload["type"]) then
            puts "This is a navigation node, there isn't an edit per se."
            LucilleCore::pressEnterToContinue()
        end
    end

    # Nx7::landing(item)
    def self.landing(item)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = Nx7::itemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts Nx7::toString(item)

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "payload: #{item["nx7Payload"]["type"]}".yellow

            filepath = Nx7::filepathForExistingItemOrError(uuid)
            puts "filepath: #{filepath}".yellow

            item["comments"].each{|comment|
                puts "[comment] #{comment}"
            }

            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)

            parents = Nx7::parents(item)
            if parents.size > 0 then
                puts ""
                puts "parents: "
                parents
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            entities = Nx7::relateds(item)
            if entities.size > 0 then
                puts ""
                puts "related: "
                entities
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            children = Nx7::children(item)
            if children.size > 0 then
                puts ""
                puts "children: "
                children
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .each{|entity|
                        store.register(entity, false)
                        puts "    #{store.prefixString()} #{Nx7::toStringForNx7Landing(entity)}"
                    }
            end

            puts ""
            puts "<n> | access | edit | export | description | datetime | payload | expose | destroy".yellow
            puts "comment | related | child | parent | upload".yellow
            puts "[link type update] parents>related | parents>children | related>children | related>parents | children>related".yellow
            puts "[network shape] select children; move to selected child | select children; move to uuid".yellow
            puts "[grid points] Nx8".yellow
            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::landing(entity)
                next
            end

            if Interpreting::match("access", input) then
                Nx7::access(item)
                next
            end

            if Interpreting::match("edit", input) then
                Nx7::edit(item)
                next
            end

            if input == "comment" then
                comment = LucilleCore::askQuestionAnswerAsString("comment: ")
                item["comments"] << comment
                Nx7::commit(item)
                next
            end

            if input == "Nx8" then
                filepath = "#{Config::pathToDesktop()}/#{CommonUtils::sanitiseStringForFilenaming(item["description"])}.Nx8"
                File.open(filepath, "w"){|f| f.puts(item["uuid"]) }
                next
            end

            if input == "child" then
                NetworkShapeAroundNode::architectureAndSetAsChild(item)
                next
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("datetime", input) then
                PolyActions::editDatetime(item)
                next
            end

            if Interpreting::match("description", input) then
                PolyActions::editDescription(item)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("payload", input) then
                puts "Your current payload is:"
                puts JSON.pretty_generate(item["nx7Payload"])
                next if !LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to override it ? : ")
                operator = Nx7::operatorForItem(item)
                nx7Payload = Nx7Payloads::interactivelyMakePayload(operator)
                puts "New payload:"
                next if !LucilleCore::askQuestionAnswerAsBoolean("Confirm : ")
                item["nx7Payload"] = nx7Payload
                Nx7::commit(item)
                next
            end

            if input == "related" then
                NetworkShapeAroundNode::architectureAndRelate(item)
                next
            end

            if input == "parent" then
                NetworkShapeAroundNode::architectureAndSetAsParent(item)
                next
            end

            if input == "unlink" then
                NetworkShapeAroundNode::selectOneRelatedAndDetach(item)
                next
            end

            if input == "upload" then
                Upload::interactivelyUploadToItem(item)
                next
            end

            if Interpreting::match("parents>children", input) then
                NetworkShapeAroundNode::selectParentsAndRecastAsChildren(item)
                next
            end

            if Interpreting::match("parents>related", input) then
                NetworkShapeAroundNode::selectParentsAndRecastAsRelated(item)
                next
            end

            if Interpreting::match("related>children", input) then
                NetworkShapeAroundNode::selectLinkedsAndRecastAsChildren(item)
                next
            end

            if Interpreting::match("children>related", input) then
                NetworkShapeAroundNode::selectChildrenAndRecastAsRelated(item)
                next
            end

            if Interpreting::match("related>parents", input) then
                NetworkShapeAroundNode::selectLinkedAndRecastAsParents(item)
                next
            end

            if Interpreting::match("select children; move to selected child", input) then
                NetworkShapeAroundNode::selectChildrenAndSelectTargetChildAndMove(item)
                next
            end

            if Interpreting::match("select children; move to uuid", input) then
                NetworkShapeAroundNode::selectChildrenAndMoveToUUID(item)
                next
            end

        }
    end
end

class Nx7Xp

    # Nx7Xp::fsck()
    def self.fsck()
        Nx7::itemsEnumerator()
            .each{|item|
                FileSystemCheck::exitIfMissingCanary()
                FileSystemCheck::fsck_MikuTypedItem(item, true)
            }
        puts "fsck completed successfully".green
    end
end

class Nx7Export

    # Nx7Export::itemRecursiveTrace(item)
    def self.itemRecursiveTrace(item)
        t1 = JSON.generate(item)
        t2 = Nx7::children(item).map{|child| Nx7Export::itemRecursiveTrace(child)}.join(":")
        Digest::SHA1.hexdigest("8b4ab1b6-71a5-42c3-872b-b98390c147bb:#{t1}:#{t2}")
    end

    # Nx7Export::itemToFoldername(item)
    def self.itemToFoldername(item)
        "(#{item["datetime"][0, 10]}) #{CommonUtils::sanitiseStringForFilenaming(item["description"])}"
    end

    # Nx7Export::recursivelyExportItemAtLocation(item, parentlocation)
    def self.recursivelyExportItemAtLocation(item, parentlocation)
        key1 = Digest::SHA1.hexdigest("#{Nx7Export::itemRecursiveTrace(item)}:#{parentlocation}")
        return if XCache::getFlag(key1)

        puts "exporting: #{parentlocation}/#{Nx7::toString(item)}"

        itemFoldername = Nx7Export::itemToFoldername(item)
        itemfolderpath = "#{parentlocation}/#{itemFoldername}"
        if !File.exists?(itemfolderpath) then
            puts "creating: #{itemfolderpath}"
            FileUtils.mkdir(itemfolderpath)
        end
        payload = item["nx7Payload"]
        if payload["type"] == "Data" then
            operator = Nx7::operatorForItem(item)
            state = payload["state"]
            GridState::exportStateAtFolder(operator, state, itemfolderpath)
        else
            Nx7::children(item).each{|child|
                Nx7Export::recursivelyExportItemAtLocation(child, itemfolderpath)
            }

            itemChildrenNamesWeHave = LucilleCore::locationsAtFolder(itemfolderpath).map{|fpath| File.basename(fpath) }
            itemChildrenNamesWeNeed = Nx7::children(item).map{|child| Nx7Export::itemToFoldername(child) }

            (itemChildrenNamesWeHave - itemChildrenNamesWeNeed).each{|childname|
                itemChildFolderpath = "#{itemfolderpath}/#{childname}"
                puts "removing : #{itemChildFolderpath}"
                LucilleCore::removeFileSystemLocation(itemChildFolderpath)
            }
        end

        XCache::setFlag(key1, true)
    end

    # Nx7Export::exportAll()
    def self.exportAll()
        foldernamesWeHave = LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/Nyx-Projection-Read-Only/Projection").map{|fpath| File.basename(fpath) }
        foldernamesWeNeed = Nx7::itemsEnumerator()
                        .map{|item|
                            (lambda {|item|
                                return nil if Nx7::parents(item).size > 0
                                Nx7Export::itemToFoldername(item)
                            }).call(item)
                        }
                        .compact

        (foldernamesWeHave - foldernamesWeNeed).each{|foldername|
            folderpath = "#{Config::pathToGalaxy()}/Nyx-Projection-Read-Only/Projection/#{foldername}"
            puts "removing : #{folderpath}"
            LucilleCore::removeFileSystemLocation(folderpath)
        }

        Nx7::itemsEnumerator()
            .each{|item|
                next if Nx7::parents(item).size > 0
                #puts "exporting: #{Nx7::toString(item)}"
                Nx7Export::recursivelyExportItemAtLocation(item, "#{Config::pathToGalaxy()}/Nyx-Projection-Read-Only/Projection")
            }
    end
end