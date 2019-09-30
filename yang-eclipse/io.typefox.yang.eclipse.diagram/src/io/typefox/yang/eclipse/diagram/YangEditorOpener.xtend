/*
 * Copyright (C) 2017 TypeFox and others.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License'); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 */
package io.typefox.yang.eclipse.diagram

import java.net.URI
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.jface.text.IDocument
import org.eclipse.lsp4j.Position
import org.eclipse.swt.widgets.Display
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.part.FileEditorInput
import org.eclipse.ui.texteditor.ITextEditor
import io.typefox.yang.eclipse.diagram.sprotty.OpenInTextEditorMessage
import org.apache.log4j.Logger

class YangEditorOpener {

	static val LOG = Logger.getLogger(YangEditorOpener)

	def openInTextEditor(OpenInTextEditorMessage message) {
		val targetFileURI = URI.create(message.location.uri)
		val targetResourcePath = targetFileURI.toResourceURI()

		val file = ResourcesPlugin.workspace.root.getFile(targetResourcePath)
		if (file.accessible) {
			val editorInput = new FileEditorInput(file)
			Display.^default.asyncExec [
				val page = PlatformUI.workbench.activeWorkbenchWindow.activePage
				val editor = if (message.forceOpen) {
						page.openEditor(editorInput, 'io.typefox.YangEditor')
					} else {
						page.findEditor(editorInput)
					}
				if (editor instanceof ITextEditor) {
					val document = editor.documentProvider.getDocument(editorInput)
					val range = message.location.range
					editor.selectAndReveal(document.getOffset(range.start), 0)
				}
			]
		} else {
			LOG.warn('Open In Text Editor: file "' + file + '" is not accessible.')
		}
	}

	def toResourceURI(URI uri) {
		for (project : ResourcesPlugin.workspace.root.projects) {
			val relativeURI = project.locationURI.relativize(uri);
			if (relativeURI !== uri) {
				return project.fullPath.append(relativeURI.toString)
			}
		}
		return new Path(uri.toString)
	}

	protected def getOffset(IDocument document, Position position) {
		document.getLineOffset(position.line) + position.character
	}

}
