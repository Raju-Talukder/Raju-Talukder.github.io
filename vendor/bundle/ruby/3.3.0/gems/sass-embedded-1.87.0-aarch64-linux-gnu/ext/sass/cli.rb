# frozen_string_literal: true

require_relative '../../lib/sass/elf'

module Sass
  module CLI
    INTERPRETER = '/lib/ld-linux-aarch64.so.1'

    INTERPRETER_SUFFIX = '/ld-linux-aarch64.so.1'

    COMMAND = [
      *(ELF::INTERPRETER if ELF::INTERPRETER != INTERPRETER && ELF::INTERPRETER&.end_with?(INTERPRETER_SUFFIX)),
      File.absolute_path('dart-sass/src/dart', __dir__).freeze,
      File.absolute_path('dart-sass/src/sass.snapshot', __dir__).freeze
    ].freeze
  end

  private_constant :CLI
end
