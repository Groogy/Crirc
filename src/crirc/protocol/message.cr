# `Message` is the object that parse the raw TCP body as a IRC message.
#
# Message are a IRC core part. They contain a command, the arguments, and
# the message (last argument in the IRC protocol).
# TODO: improve the message to appear in as the last argument. cf: fast_irc
class Crirc::Protocol::Message
  # Raw message without parsing
  getter raw : String

  # Source of the message (ex: "0", "abc@xyz", ...)
  getter source : String

  # The command ("PRIVMSG", "PING", ...)
  getter command : String

  # The arguments as a string ("user1 +0", "pingmessage", ...)
  getter arguments : String?

  # The tags as a string (tag-name-1=<tag-value-1>;tag-name-2=<tag-value-2>;)
  getter tags : String?

  # The last argument when ":" ("This is a privmsg message", ...)
  getter message : String?

  R_SRC     = "(\\:(?<src>[^[:space:]]+) )"
  R_CMD     = "(?<cmd>[A-Z]+|\\d{3})"
  R_ARG_ONE = "(?:[^: ][^ ]*)"
  R_TAG     = "(\\@(?<tag>#{R_ARG_ONE}(?: #{R_ARG_ONE})*) )"
  R_ARG     = "(?: (?<arg>#{R_ARG_ONE}(?: #{R_ARG_ONE})*))"
  R_MSG     = "(?: \\:(?<msg>.+)?)"

  def initialize(@raw)
    m = raw.strip.match(/\A#{R_TAG}?#{R_SRC}?#{R_CMD}#{R_ARG}?#{R_MSG}?\Z/)
    raise ParsingError.new "The message (#{@raw}) is invalid" if m.nil?
    @source = m["src"]? || "0"
    @command = m["cmd"] # ? || raise InvalidMessage.new("No command to parse in \"#{raw}\"")
    @arguments = m["arg"]?
    @message = m["msg"]?
    @tags = m["tag"]? 
  end

  # Concatenation of `arguments` and `message`.
  # If the message exists, it is preceded by ':'
  #
  # ```
  # msg.raw_arguments # => "user1 +0 :do something"
  # ```
  def raw_arguments : String
    return "" if @arguments.nil? && @message.nil?
    return @arguments.to_s if @message.nil?
    return ":#{@message}" if @arguments.nil?
    return "#{@arguments} :#{@message}"
  end

  # The arguments formated into an Array.
  #
  # ```
  # msg.argument_list # => ["user1", "+0"]
  # ```
  def argument_list : Array(String)
    return Array(String).new if @arguments.nil? && @message.nil?
    return (@arguments.as(String)).split(" ") if @message.nil?
    return [@message.as(String)] if @arguments.nil?
    return (@arguments.as(String)).split(" ") << (@message.as(String))
  end

  # The tags formated into an array
  # If the message exists, it is preceded by ':'
  #
  # ```
  # msg.raw_arguments # => "user1 +0 :do something"
  # ```
  def tags_list : Hash(String, String)
    result = {} of String => String
    if tags = @tags
      tags.split(";") do |tag|
        arr = tag.split("=")
        result[arr[0]] = arr[1]
      end
    end
    result
  end

  class ParsingError < Exception; end
end
