# frozen_string_literal: true

require "extends/controllers/decidim/devise/blank_account_controller_extends"
require "extends/cells/decidim/content_blocks/hero_cell_extends"
require "extends/uploaders/decidim/application_uploader_extends"
require "extends/lib/decidim/proposals/imports/proposal_answer_creator_extends"

require "decidim/exporters/serializer"
require "extends/lib/decidim/forms/user_answers_serializer_extend"

require "extends/omniauth/strategies/openid_connect_extends"
