#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../common'

describe "master courses - master courses - file locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @filename = 'file.txt'
    @original_file = Attachment.create!(:filename => @filename, :uploaded_data => StringIO.new('1'),
      :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
    @tag = @template.create_content_tag_for!(@original_file)

  end

  before :each do
    user_session(@teacher)
  end

  it "should show the manageable cog-menu options when a file is locked" do
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_from.id}/files"

    expect(f('.ef-directory .ef-item-row .lock-icon')).to contain_css('.icon-lock')

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Download")
    expect(f('.al-options').text).to include("Rename")
    expect(f('.al-options').text).to include("Move")
    expect(f('.al-options').text).to include("Delete")
  end

  it "should show the manageable cog-menu options when a folder contains a locked file" do
    subfolder = Folder.root_folders(@copy_from).first.sub_folders.create!(:name => "subfolder", :context => @copy_from)
    @original_file.folder = subfolder
    @original_file.save!
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_from.id}/files"

    expect(f('.ef-item-row .ef-name-col').text).to include("subfolder") # we're looking at the folder right?
    expect(f('.ef-directory .ef-item-row')).not_to contain_css('.icon-lock') # master folders never have locks

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Download")
    expect(f('.al-options').text).to include("Rename")
    expect(f('.al-options').text).to include("Move")
    expect(f('.al-options').text).to include("Delete")
  end

  it "should show the manageable cog-menu options when a file is unlocked" do
    get "/courses/#{@copy_from.id}/files"

    expect(f('.ef-directory .ef-item-row .lock-icon')).to contain_css('.icon-unlock')

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Download")
    expect(f('.al-options').text).to include("Rename")
    expect(f('.al-options').text).to include("Move")
    expect(f('.al-options').text).to include("Delete")
  end

  it "should show the manageable cog-menu options when a folder contains an unlocked file" do
    subfolder = Folder.root_folders(@copy_from).first.sub_folders.create!(:name => "subfolder", :context => @copy_from)
    @original_file.folder = subfolder
    @original_file.save!
    get "/courses/#{@copy_from.id}/files"

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Download")
    expect(f('.al-options').text).to include("Rename")
    expect(f('.al-options').text).to include("Move")
    expect(f('.al-options').text).to include("Delete")
  end
end
