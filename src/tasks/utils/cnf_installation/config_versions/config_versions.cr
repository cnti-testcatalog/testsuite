module CNFInstall
  module Config 
    # REQUIRES FUTURE EXTENSION in case of new config format.
    enum ConfigVersion
      V1
      V2
      Latest = V2
    end
  end
end