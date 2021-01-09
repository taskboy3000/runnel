export class Template {
    constructor (templateNodeId) {
        this.templateNode = document.getElementById(templateNodeId); // This should be a <template> node
        if (!this.templateNode) {
            console.error("Cannot find node " + templateNodeId);
        }

        if (!this.templateNode.content) {
            console.error("Node appears to be empty");
        }
    }

    // data is an array of objects:
    // [
    //   { 'value': 'replacement string', // REQUIRED
    //     'target': 'target string', // REQUIRED: a query selector for node
    //     'attr': 'attribute name', // OPTIONAL: set this attribute in found targets
    //     'type': '[html|text]', // OPTIONAL: default is html (unused with 'attr')
    //   }
    render (replacementList) {
        let frag = this.templateNode.content.cloneNode(true);
        for (let rec of replacementList) {
            let nodes = frag.querySelectorAll(rec.target);
            if (!nodes) {
                console.warn("Cannot find target node: " + rec.target);
                return;
            }

            for (let node of nodes) {
                if (rec.attr) {
                    node.setAttribute(rec.attr, rec.value);
                } else if (rec.type == 'text') {
                    node.innerText = rec.value;
                } else {
                    node.innerHTML = rec.value;
                }
            }
        }

        return frag;
    }
}
