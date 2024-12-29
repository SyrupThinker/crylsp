require "yaml"

class CryLSP::Workspace
  # Finds all relevant entrypoints for the workspace
  def self.find_entrypoints(root : Path) : Array(Path)
    shards_path = root / "shard.yml"
    return [] of Path unless File.file? shards_path

    shards = File.open shards_path do |io|
      YAML.parse io
    end
    return [] of Path unless targets = shards["targets"]?

    targets.as_h
      .select { |_, target| target["main"]? }
      .compact_map { |_, target|
        target_path = root / target["main"].to_s
        File.file?(target_path) ? target_path : nil
      }
  end
end
