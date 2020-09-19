class ApplicationRecord < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  self.abstract_class = true

  def file_url_of(file)
    if !Rails.env.production?
      file.attached? ? rails_blob_url(file) : nil
    else
      file.attached? ? file.service_url : nil
    end
  end

  def file_path_of(file)
    if !Rails.env.production?
      file.attached? ? rails_blob_path(file) : nil
    else
      file.attached? ? file.service_url : nil
    end
  end

  def first_files_url_of(files)
    if !Rails.env.production?
      files.attached? ? rails_blob_url(files.first) : nil
    else
      files.attached? ? files.first.service_url : nil
    end
  end

  def last_files_url_of(files)
    if !Rails.env.production?
      files.attached? ? rails_blob_url(files.last) : nil
    else
      files.attached? ? files.last.service_url : nil
    end
  end
end
