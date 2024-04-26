
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull(thread)
    def self.interactivelyIssueNewOrNull(thread)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "parentuuid-0032", thread["uuid"])
        Cubes2::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(parent, uuid, description)
    def self.descriptionToTask1(parent, uuid, description)
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "parentuuid-0032", parent["uuid"])
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTodos::performance(item)
    def self.performance(item)
        Bank2::recoveredAverageHoursPerDay(item["uuid"])
    end

    # NxTodos::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}"
    end

    # NxTodos::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxTodo")
            .select{|item| Catalyst::isOrphan(item) }
            .sort_by{|item| item["unixtime"] }
    end

    # NxTodos::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxTodo").each{|item|
            if item["parentuuid-0032"].nil? then
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "85e2e9fe-ef3d-4f75-9330-2804c4bcd52b") # core infinity
                next
            end
            parent = Cubes2::itemOrNull(item["parentuuid-0032"])
            if parent.nil? then
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", nil)
                next
            end
            if !["NxThread", "TxCore"].include?(parent["mikuType"]) then
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", nil)
                next
            end
        }

        
    end
end
