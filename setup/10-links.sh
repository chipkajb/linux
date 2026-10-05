#!/usr/bin/env bash
# Publish repo CLI tools onto the system PATH.

step_links() {
    link_bin
    ui::hint "bin/* → /usr/local/bin"
}
