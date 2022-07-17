
# encoding: UTF-8

class NxLink

    # NxLink::issue(node1uuid, node2uuid)
    def self.issue(node1uuid, node2uuid)
        Fx18s::setsAdd2(node1uuid, "network-link", node2uuid, node2uuid)
        Fx18s::setsAdd2(node2uuid, "network-link", node1uuid, node1uuid)
    end

    # NxLink::unlink(node1uuid, node2uuid)
    def self.unlink(node1uuid, node2uuid)
        Fx18s::setsRemove2(node1uuid, "network-link", node2uuid)
        Fx18s::setsRemove2(node2uuid, "network-link", node1uuid)
    end

    # NxLink::linkedUUIDs(uuid)
    def self.linkedUUIDs(uuid)
        Fx18s::setsItems(uuid, "network-link")
    end
end
