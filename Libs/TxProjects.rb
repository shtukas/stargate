
# encoding: UTF-8

class TxProjects

    # ----------------------------------------------------------------------
    # IO

    # TxProjects::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
            "ax39"        => JSON.parse(Fx18s::getAttributeOrNull(objectuuid, "ax39")),
        }
        raise "(error: 7aa5e8bd-8ebf-4098-b125-f95e620f49b8) item: #{item}" if item["mikuType"] != "TxProject"
        item
    end

    # TxProjects::items()
    def self.items()
        Librarian::mikuTypeUUIDs("TxProject").map{|objectuuid|
            TxProjects::objectuuidToItem(objectuuid)
        }
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxProjects::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        uuid = SecureRandom.uuid

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid2)
        Fx18s::setAttribute2(uuid, "mikuType",    "TxProject")
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "ax39",        JSON.generate(ax39))

        uuid
    end

    # TxProjects::architectOneOrNull() # objectuuid or null
    def self.architectOneOrNull()
        items = TxProjects::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| LxFunction::function("toString", item) })
        return item["uuid"] if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new project ? ") then
            return TxProjects::interactivelyIssueNewItemOrNull()
        end
    end

    # ----------------------------------------------------------------------
    # Elements

    # TxProjects::addElement(projectuuid, itemuuid)
    def self.addElement(projectuuid, itemuuid)
        Fx18s::makeNewFile(projectuuid)
        Fx18s::setsAdd2(projectuuid, "project-items-3f154988", itemuuid, itemuuid)
    end

    # TxProjects::removeElement(project, uuid)
    def self.removeElement(project, uuid)
        Fx18s::makeNewFile(project["uuid"])
        Fx18s::setsRemove2(project["uuid"], "project-items-3f154988", uuid)
    end

    # TxProjects::elementuuids(project)
    def self.elementuuids(project)
        Fx18s::makeNewFile(project["uuid"])
        Fx18s::setsItems(project["uuid"], "project-items-3f154988")
    end

    # TxProjects::uuidIsProjectElement(uuid)
    def self.uuidIsProjectElement(uuid)
        TxProjects::items().any?{|project| TxProjects::elementuuids(project).include?(uuid) }
    end

    # TxProjects::getProjectPerElementUUIDOrNull(uuid)
    def self.getProjectPerElementUUIDOrNull(uuid)
        TxProjects::items()
            .select{|project| TxProjects::elementuuids(project).include?(uuid) }
            .first
    end

    # ----------------------------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(project) #{item["description"]} #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxProjects::nx20s()
    def self.nx20s()
        TxProjects::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxProjects::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end

    # TxProjects::itemsForSection1()
    def self.itemsForSection1()
        TxProjects::items()
    end

    # TxProjects::elementsDepth()
    def self.elementsDepth()
        10
    end

    # TxProjects::section2Xp()
    def self.section2Xp()
        itemsToKeepOrReInject = []
        itemsToDelistIfPresentInListing = []

        TxProjects::items()
            .each{|project|
                if Ax39::itemShouldShow(project) or NxBallsService::isRunning(project["uuid"]) then
                    # itemsToKeepOrReInject << project
                    # TODO:
                else
                    itemsToDelistIfPresentInListing << project["uuid"]
                end
            }

        TxProjects::items()
            .each{|project|
                TxProjects::elementuuids(project)
                    .first(TxProjects::elementsDepth())
                    .select{|elementuuid|  
                        if NxBallsService::isRunning(elementuuid) then
                            # itemsToKeepOrReInject << item
                            # TODO:
                        else
                            itemsToDelistIfPresentInListing << elementuuid
                        end   
                    }
            }
        [itemsToKeepOrReInject, itemsToDelistIfPresentInListing]
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxProjects::dive()
    def self.dive()
        loop {
            project = LucilleCore::selectEntityFromListOfEntitiesOrNull("project", TxProjects::items(), lambda{|item| TxProjects::toString(item) })
            break if project.nil?
            Landing::landing(project)
        }
    end

    # TxProjects::startAccessProject(project)
    def self.startAccessProject(project)
        elementuuids = TxProjects::elementuuids(project).take(TxProjects::elementsDepth())
        elements = elementuuids.map{|elementuuid| Fx18Xp::objectuuidToItemOrNull(elementuuid) }
        if elements.size == 1 then
            LxAction::action("..", elements[0])
            return
        end

        element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|item| LxFunction::function("toString", item) } )
        return if element.nil?
        LxAction::action("..", element)
    end

    # TxProjects::interactivelyProposeToAttachTaskToProject(itemuuid)
    def self.interactivelyProposeToAttachTaskToProject(itemuuid)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to a project ? ") then
            projectuuid = TxProjects::architectOneOrNull()
            return if projectuuid.nil?
            TxProjects::addElement(projectuuid, itemuuid)
        end
    end
end
