module CNFInstall
  module Config
    # The rules need to be somewhat explicit, different approaches have been attempted
    # but due to crystals strict typing system they have not been viable/would be too complicated.
    # 
    # In case of future extension, create a new transformation rules class (VxToVyTransformation),
    # This class should inherit the TransformationBase class and make use of process_data
    # function at the end of its transform function.
    class TransformationBase
      @new_config : YAML::Any
  
      def initialize(@old_config : ConfigV1)
        @new_config = YAML::Any.new({} of YAML::Any => YAML::Any)
      end
  
      # Recursively remove any empty hashes/arrays/values and convert data to YAML::Any.
      private def process_data(data : Hash | Array | String | Nil) : YAML::Any?
        case data
        when Array
          processed_array = data.map { |item| process_data(item) }.compact
          processed_array.empty? ? nil : YAML::Any.new(processed_array)
        when Hash
          processed_hash = Hash(YAML::Any, YAML::Any).new
          data.each do |k, v|
            processed_value = process_data(v)
            processed_hash[YAML::Any.new(k)] = processed_value unless processed_value.nil?
          end
          processed_hash.empty? ? nil : YAML::Any.new(processed_hash)
        when String
          YAML::Any.new(data)
        else
          nil
        end
      end
    end
  end
end