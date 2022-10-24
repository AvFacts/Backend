# frozen_string_literal: true

json.array! @episodes, partial: "episodes/episode", as: :episode
