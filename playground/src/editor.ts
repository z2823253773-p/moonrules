import { json } from "@codemirror/lang-json";
import { EditorState } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";
import { basicSetup } from "codemirror";

export class JsonEditor {
  private readonly view: EditorView;

  constructor(
    parent: HTMLElement,
    value: string,
    onRun: () => void,
    ariaLabel: string,
  ) {
    this.view = new EditorView({
      parent,
      state: EditorState.create({
        doc: value,
        extensions: [
          basicSetup,
          json(),
          keymap.of([
            {
              key: "Mod-Enter",
              run: () => {
                onRun();
                return true;
              },
            },
          ]),
          EditorView.contentAttributes.of({ "aria-label": ariaLabel }),
          EditorView.lineWrapping,
        ],
      }),
    });
  }

  getValue(): string {
    return this.view.state.doc.toString();
  }

  setValue(value: string): void {
    this.view.dispatch({
      changes: { from: 0, to: this.view.state.doc.length, insert: value },
    });
  }

  format(): void {
    this.setValue(JSON.stringify(JSON.parse(this.getValue()), null, 2));
  }
}
