class SearchData
  def initialize(entry)
    @entry = entry
  end

  def to_h
    {}.tap do |hash|
      hash[:id]        = @entry.id
      hash[:feed_id]   = @entry.feed_id
      hash[:title]     = ContentFormatter.summary(@entry.title)
      hash[:url]       = @entry.fully_qualified_url
      hash[:author]    = @entry.author
      hash[:content]   = text
      hash[:published] = @entry.published.iso8601
      hash[:updated]   = @entry.updated_at.iso8601
      hash[:link]      = links
      if @entry.tweet?
        hash[:twitter_screen_name] = "#{@entry.main_tweet.user.screen_name} @#{@entry.main_tweet.user.screen_name}"
        hash[:twitter_name]        = @entry.main_tweet.user.name
        hash[:twitter_retweet]     = @entry.tweet.retweeted_status?
        hash[:twitter_quoted]      = @entry.tweet.quoted_status?
        hash[:twitter_media]       = @entry.twitter_media?
        hash[:twitter_image]       = twitter_image
        hash[:twitter_link]        = twitter_link
      end
    end
  end

  def document
    @document ||= Loofah.fragment(@entry.content).scrub!(:prune)
  end

  def text
    document
      .to_text(encode_special_chars: false)
      .gsub(/\s+/, " ")
      .squish
  end

  def tweets
    @tweets ||= begin
      [].tap do |array|
        array.push(@entry.main_tweet)
        array.push(@entry.main_tweet.quoted_status) if @entry.main_tweet.quoted_status?
      end
    end
  end

  def twitter_image
    !!(tweets.find { |tweet| tweet.media? rescue nil })
  end

  def twitter_link
    !!(tweets.find { |tweet| tweet.urls? })
  end

  def links
    links = [@entry.fully_qualified_url]
    document.css("a").each do |link|
      links.push(link["href"])
    end
    links.map do |link|
      Addressable::URI.parse(link)&.host rescue nil
    end.compact.uniq
  end
end