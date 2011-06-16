# Rails is a shitbag for thinking that models and hashes are mutually exclusive
# so we have to hack Hash
class Hash
  def self.===(other)
    return false if self == Hash && other.is_a?(CouchRecord::Base)
    super
  end
end