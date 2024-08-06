module CNFInstall
  module Config
    class ConfigBase
      include YAML::Serializable
      include YAML::Serializable::Strict
    end
  end
end