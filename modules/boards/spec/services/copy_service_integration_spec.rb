#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Projects::CopyService, 'integration', type: :model do
  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: source,
                      member_through_role: role)
  end
  let(:role) { FactoryBot.create :role, permissions: %i[copy_projects] }

  let(:source) { FactoryBot.create :project, enabled_module_names: %w[boards work_package_tracking] }
  let!(:wp_1) { FactoryBot.create(:work_package, project: source, subject: 'Second') }
  let!(:wp_2) { FactoryBot.create(:work_package, project: source, subject: 'First') }

  let!(:board_view) { FactoryBot.create :board_grid_with_query, project: source, name: 'My Board' }
  let(:query) { board_view.contained_queries.first }

  before do
    ::OrderedWorkPackage.create(query: query, work_package: wp_1, position: 1234)
    ::OrderedWorkPackage.create(query: query, work_package: wp_2, position: -1000)
  end

  let(:instance) do
    described_class.new(source: source, user: current_user)
  end
  let(:only_args) { %w[work_packages boards] }
  let(:target_project_params) do
    { name: 'Some name', identifier: 'some-identifier' }
  end
  let(:params) do
    { target_project_params: target_project_params, only: only_args }
  end

  describe 'call' do
    subject { instance.call(params) }
    let(:project_copy) { subject.result }
    let(:copied_boards) { Boards::Grid.where(project: project_copy) }
    let(:copied_board) { copied_boards.first }

    it 'will copy the boards with the order correct' do
      expect(subject).to be_success

      expect(copied_boards.count).to eq 1

      # Expect board name to match
      expect(copied_board.name).to eq 'My Board'

      # Expect query to differ
      query_id = copied_board.widgets.first.options['queryId']
      expect(query_id.to_i).not_to eq(query.id)

      # Expect query to be in correct project
      query = Query.find(query_id)
      expect(query.project).to eq project_copy

      wps = query.ordered_work_packages
      expect(wps.count).to eq 2

      expect(wps[0].work_package.subject).to eq 'First'
      expect(wps[0].position).to eq -1000
      expect(wps[0].work_package.id).not_to eq wp_2.id

      expect(wps[1].work_package.subject).to eq 'Second'
      expect(wps[1].position).to eq 1234
      expect(wps[1].work_package.id).not_to eq wp_1.id
    end
  end
end
