require 'drop_presenter'

describe DropPresenter do

  describe '#render_html' do
    let(:drop) { stub :drop, beta?:     beta,
                             bookmark?: bookmark,
                             image?:    image,
                             text?:     text,
                             markdown?: markdown,
                             pending?:  pending }
    let(:beta)     { false }
    let(:bookmark) { false }
    let(:image)    { false }
    let(:text)     { false }
    let(:markdown) { false }
    let(:pending)  { false }
    subject { DropPresenter.new drop, template }

    describe 'a bookmark drop' do
      let(:bookmark) { true }
      let(:template) do
        stub request:         stub(path: '/slug'),
             cache_control:   nil,
             redirect_to_api: nil
      end

      it 'redirects to the api' do
        template.should_receive(:redirect_to_api).with(no_args)
        subject.render_html
      end

      it 'is cached' do
        template.should_receive(:cache_control).with(:public, max_age: 900)
        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }
        it 'redirects to the api' do
          template.should_receive(:redirect_to_api).with(no_args)
          subject.render_html
        end
      end
    end

    describe 'a pending drop' do
      let(:image)    { true }
      let(:text)     { true }
      let(:markdown) { true }
      let(:pending)  { true }
      let(:content)  { 'content' }
      let(:template) { stub erb: content }

      it 'renders the erb template with new layout' do
        template.
          should_receive(:erb).
          with(:new_waiting, layout: :new_layout, locals: { drop: drop, body_id: 'waiting' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_waiting, layout: :new_layout, locals: { drop: drop, body_id: 'waiting' })

          subject.render_html
        end
      end
    end

    describe 'an image drop' do
      let(:image)    { true }
      let(:content)  { 'content' }
      let(:template) { stub erb: content, cache_control: nil }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:image, layout: :layout, locals: { drop: drop, body_id: 'image' })

        subject.render_html
      end

      it 'is cached' do
        template.should_receive(:cache_control).with(:public, max_age: 900)
        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_image, layout: :new_layout, locals: { drop: drop, body_id: 'image' })

          subject.render_html
        end
      end
    end

    describe 'a text drop' do
      let(:text)     { true }
      let(:content)  { 'content' }
      let(:template) { stub erb: content }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:text, layout: :layout, locals: { drop: drop, body_id: 'text' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the erb template' do
          template.
            should_receive(:erb).
            with(:new_markdown, layout: :new_layout, locals: { drop: drop, body_id: 'text' })

          subject.render_html
        end
      end
    end

    describe 'a markdown drop' do
      let(:text)     { true }
      let(:markdown) { true }
      let(:content)  { 'content' }
      let(:template) { stub erb: content }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:text, layout: :layout, locals: { drop: drop, body_id: 'text' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_markdown, layout: :new_layout, locals: { drop: drop, body_id: 'text' })

          subject.render_html
        end
      end
    end

    describe 'an unknown drop' do
      let(:content)  { 'content' }
      let(:template) { stub erb: content, cache_control: nil }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:other, layout: :layout, locals: { drop: drop, body_id: 'other' })

        subject.render_html
      end

      it 'is cached' do
        template.should_receive(:cache_control).with(:public, max_age: 900)
        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_download, layout: :new_layout, locals: { drop: drop, body_id: 'other' })

          subject.render_html
        end
      end
    end
  end

  describe '#render_json' do
    let(:template) { stub }
    let(:drop) { stub data: { key: 'value' } }
    subject { DropPresenter.new drop, template }

    it 'returns the drop as json' do
      subject.render_json.should == '{"key":"value"}'
    end
  end

end
