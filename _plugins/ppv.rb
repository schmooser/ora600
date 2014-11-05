class Jekyll::Converters::Markdown::PPV
  def initialize(config)
    require 'kramdown'
    require 'nokogiri'
    @config = config
  rescue LoadError
    STDERR.puts 'You are missing a library required for Markdown. Please run:'
    STDERR.puts '  $ [sudo] gem install kramdown'
    STDERR.puts '  $ [sudo] gem install nokogiri'
    raise FatalException.new("Missing dependency: kramdown")
    raise FatalException.new("Missing dependency: nokogiri")
  end

  def convert(content)
    html = Kramdown::Document.new(content).to_html
    doc = Nokogiri::HTML(html)

    ps = doc.css "p:has(img:gt(1))" # paragraphs with more than 1 image
    ps.each do |p|
      p.css("br").each{ |br| br.remove }

      imgs = p.css "img"
      imgs.wrap "<div class='col-md-6'></div>"
      #imgs.wrap("<div class='pure-u-1 pure-u-md-1-%s'></div>" % imgs.length)

      p.name = 'div'
      p['class'] = 'row'
    end

    doc.css("p:has(img)").each do |p|
      p.name = 'div'
      p['class'] = 'p'
    end

    # turn every img into div with caption
    doc.css("img").wrap "<div class='photo-box'></div>"
    doc.css(".photo-box").each do |box|
      img = box.at_css "img"
      img['class'] = 'img-responsive'
      if not img['alt'].empty?
        caption = Nokogiri::XML::Node.new "span", doc
        caption.content = img['alt']
        img.add_next_sibling caption
      end
    end
    doc.css(".photo-box span").wrap "<aside></aside>"

    doc.css('p').each do |p|
      p.remove if p.content.strip.empty?
    end

    if doc.at('body').nil?
      'nil'
    else
      doc.at('body').inner_html
    end
  end
end
