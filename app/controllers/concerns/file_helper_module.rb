module FileHelperModule

  # attachedファイルのリンク用データセット
  def file_link(file)
    return nil unless file.attached?

    { filename: file.filename, url: url_for(file) }
  end
end