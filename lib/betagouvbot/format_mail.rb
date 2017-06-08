# encoding: utf-8
# frozen_string_literal: true

require 'kramdown'

module BetaGouvBot
  class FormatMail < Hash
    class << self
      def to_rules
        @rules ||= {
          21 => { mail: from_file('data/mail_3w.md', ['{{author.id}}@beta.gouv.fr']) },
          14 => { mail: from_file(
            'data/mail_2w.md',
            ['{{author.id}}@beta.gouv.fr', 'contact@beta.gouv.fr']
          ) },
          1  => { mail: from_file('data/mail_1day.md', ['{{author.id}}@beta.gouv.fr']) },
          -1 => { mail: from_file('data/mail_after.md', ['contact@beta.gouv.fr']) }
        }
      end

      # @note Email data files consist of 1 subject line plus body
      def from_file(body_path, recipients = [], sender = 'secretariat@beta.gouv.fr')
        subject, *rest = File.readlines(body_path)
        new(subject.strip, rest.join, recipients, sender)
      end
    end

    attr_reader :subject, :body_t, :recipients, :sender

    def initialize(subject, body_t, recipients, sender)
      @subject    = subject
      @body_t     = body_t
      @recipients = recipients
      @sender     = sender
      super()
    end

    def call(context)
      itself
        .send(:add_personalisations, context)
        .send(:add_from, context)
        .send(:add_content, context)
    end

    private

    def add_personalisations(context)
      merge!(
        personalisations: [
          to: recipients.map { |mail| { email: render_template(mail, context) } },
          subject: render_template(subject, context)
        ]
      )
    end

    def add_from(context)
      merge!(from: { email: render_template(sender, context) })
    end

    def add_content(context)
      merge!(
        content: [
          type: 'text/html',
          value: render_document(render_template(body_t, context))
        ]
      )
    end

    def render_template(template, context)
      template_builder
        .parse(template)
        .render(context)
    end

    def render_document(md_source)
      document_builder
        .new(md_source)
        .to_html
    end

    def template_builder
      Liquid::Template
    end

    def document_builder
      Kramdown::Document
    end
  end
end
