#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Budgets
      class BudgetRepresenter < ::API::Decorators::Single
        property :id, render_nil: true
        property :project_id
        property :project_name, getter: -> (*) { project.try(:name) }
        property :subject, render_nil: true
        property :description, render_nil: true
        property :type, render_nil: true
        property :fixed_date, getter: -> (*) { created_on.utc.iso8601 }, render_nil: true
        property :created_at, getter: -> (*) { created_on.utc.iso8601 }, render_nil: true
        property :updated_at, getter: -> (*) { updated_on.utc.iso8601 }, render_nil: true

        property :author, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !author.nil? }

        private

        def _type
          'Budget'
        end
      end
    end
  end
end
