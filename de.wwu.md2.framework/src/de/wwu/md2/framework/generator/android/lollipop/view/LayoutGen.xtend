package de.wwu.md2.framework.generator.android.lollipop.view

import de.wwu.md2.framework.generator.IExtendedFileSystemAccess
import de.wwu.md2.framework.generator.android.lollipop.Settings
import de.wwu.md2.framework.generator.android.lollipop.util.MD2AndroidLollipopUtil
import de.wwu.md2.framework.mD2.Button
import de.wwu.md2.framework.mD2.ContainerElement
import de.wwu.md2.framework.mD2.ContainerElementReference
import de.wwu.md2.framework.mD2.ContentContainer
import de.wwu.md2.framework.mD2.FlowDirection
import de.wwu.md2.framework.mD2.FlowLayoutPane
import de.wwu.md2.framework.mD2.FlowLayoutPaneFlowDirectionParam
import de.wwu.md2.framework.mD2.GridLayoutPane
import de.wwu.md2.framework.mD2.GridLayoutPaneColumnsParam
import de.wwu.md2.framework.mD2.GridLayoutPaneRowsParam
import de.wwu.md2.framework.mD2.Label
import de.wwu.md2.framework.mD2.SubViewContainer
import de.wwu.md2.framework.mD2.TextInput
import de.wwu.md2.framework.mD2.TextInputType
import de.wwu.md2.framework.mD2.ViewElement
import de.wwu.md2.framework.mD2.ViewGUIElementReference
import de.wwu.md2.framework.mD2.WidthParam
import de.wwu.md2.framework.mD2.WorkflowElementReference
import java.io.StringWriter
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.OutputKeys
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.w3c.dom.Document
import org.w3c.dom.Element

class LayoutGen {

	def static generateLayouts(IExtendedFileSystemAccess fsa, String rootFolder, String mainPath, String mainPackage,
		Iterable<ContainerElement> rootViews, Iterable<WorkflowElementReference> startableWorkflowElements) {
			
		fsa.generateFile(rootFolder + Settings.LAYOUT_PATH + "activity_start.xml",
				generateStartLayout(mainPackage, startableWorkflowElements))
				
		rootViews.forEach [ rv |
			fsa.generateFile(rootFolder + Settings.LAYOUT_PATH + "activity_" + rv.name.toLowerCase + ".xml",
				generateLayout(mainPackage, rv))
		]
	}

	
	protected static def generateStartLayout(String mainPackage, Iterable<WorkflowElementReference> wfes) {
		val docFactory = DocumentBuilderFactory.newInstance
		val docBuilder = docFactory.newDocumentBuilder

		// create doc and set namespace definitions
		val doc = docBuilder.newDocument
		val generationComment = doc.createComment("generated in de.wwu.md2.framework.generator.android.lollipop.view.Layout.generateStartLayout()")
		doc.appendChild(generationComment)

		// create root element
		var Element rootElement = doc.createElement("ScrollView")
		
		// set attributes
		rootElement.setAttribute("android:paddingBottom", "@dimen/activity_vertical_margin")
		rootElement.setAttribute("android:paddingLeft", "@dimen/activity_horizontal_margin")
		rootElement.setAttribute("android:paddingRight", "@dimen/activity_horizontal_margin")
		rootElement.setAttribute("android:paddingTop", "@dimen/activity_vertical_margin")
		rootElement.setAttribute("android:layout_height", "match_parent")
		rootElement.setAttribute("android:layout_width", "match_parent")
		rootElement.setAttribute("android:orientation", "vertical")		
		rootElement.setAttribute("tools:context", mainPackage + ".StartActivity")

		rootElement.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:android",
			"http://schemas.android.com/apk/res/android")
		rootElement.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:tools", "http://schemas.android.com/tools")

		doc.appendChild(rootElement)
		
		var Element rootContainer = doc.createElement(Settings.MD2LIBRARY_VIEW_FLOWLAYOUTPANE)
		rootContainer.setAttribute("android:layout_height", "wrap_content")
		rootContainer.setAttribute("android:layout_width", "match_parent")
		rootContainer.setAttribute("android:orientation", "vertical")		
		rootElement.appendChild(rootContainer)
		
		// add buttons
		for(wfe : wfes){
			var btnElement = doc.createElement(Settings.MD2LIBRARY_VIEW_BUTTON)
			btnElement.setAttribute("android:id", "@id/startActivity_" + wfe.workflowElementReference.name + "Button")
 			btnElement.setAttribute("android:layout_width", "match_parent")
 			btnElement.setAttribute("android:layout_height", "wrap_content")
 			btnElement.setAttribute("android:layout_gravity", "fill_horizontal")
 			btnElement.setAttribute("android:text", "@string/" + MD2AndroidLollipopUtil.getQualifiedNameAsString(wfe, "_") + "_alias")
 			rootContainer.appendChild(btnElement);
		}

		// return xml file as string
		val transformerFactory = TransformerFactory.newInstance
		val transformer = transformerFactory.newTransformer
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes")
		val writer = new StringWriter
		transformer.transform(new DOMSource(doc), new StreamResult(writer))
		return writer.buffer.toString
	}

	protected static def generateLayout(String mainPackage, ContainerElement rv) {
		val docFactory = DocumentBuilderFactory.newInstance
		val docBuilder = docFactory.newDocumentBuilder

		// create doc and set namespace definitions
		val doc = docBuilder.newDocument
		val generationComment = doc.createComment("generated in de.wwu.md2.framework.generator.android.lollipop.view.Layout.generateLayout()")
		doc.appendChild(generationComment)

		// create root element
		var Element rootElement = doc.createElement("ScrollView")
		/*switch rv {
			FlowLayoutPane: rootElement = createFlowLayoutPaneElement(doc, rv)
			GridLayoutPane: rootElement = createGridLayoutPaneElement(doc, rv)
			default: return ""
		}*/
		
		// special settings for root attributes
		rootElement.setAttribute("android:layout_width", "match_parent")
		rootElement.setAttribute("android:layout_height", "match_parent")
		rootElement.setAttribute("android:paddingBottom", "@dimen/activity_vertical_margin")
		rootElement.setAttribute("android:paddingLeft", "@dimen/activity_horizontal_margin")
		rootElement.setAttribute("android:paddingRight", "@dimen/activity_horizontal_margin")
		rootElement.setAttribute("android:paddingTop", "@dimen/activity_vertical_margin")
		rootElement.setAttribute("tools:context", mainPackage + "." + rv.name + "Activity")

		doc.appendChild(rootElement)

		rootElement.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:android",
			"http://schemas.android.com/apk/res/android")
		rootElement.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:tools", "http://schemas.android.com/tools")

		var Element rootContainer = null
		
		switch rv {
			FlowLayoutPane: rootContainer = createFlowLayoutPaneElement(doc, rv)
			GridLayoutPane: rootContainer = createGridLayoutPaneElement(doc, rv)
			default: return ""
		}
		
		rootContainer.setAttribute("android:layout_width", "match_parent")
		rootElement.appendChild(rootContainer)

		// depth first search to generate elements for all children
		switch rv {
			ContentContainer:
				for (elem : rv.elements) {
					createChildrenElements(doc, rootContainer, elem)
				}
			SubViewContainer:
				for (elem : rv.elements) {
					switch elem {
						ContainerElement: createChildrenElements(doc, rootContainer, elem)
						ContainerElementReference: createChildrenElements(doc, rootContainer, elem.value)
					}
				}
		}

		// return xml file as string
		val transformerFactory = TransformerFactory.newInstance
		val transformer = transformerFactory.newTransformer
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes")
		val writer = new StringWriter
		transformer.transform(new DOMSource(doc), new StreamResult(writer))
		return writer.buffer.toString
	}

	protected static def void createChildrenElements(Document doc, Element element, ViewElement viewElement) {
		var Element newElement = null
		switch viewElement {
			ViewGUIElementReference:
				createChildrenElements(doc, element, viewElement.value)
			FlowLayoutPane: {
				newElement = createFlowLayoutPaneElement(doc, viewElement)
				for (elem : viewElement.elements) {
					createChildrenElements(doc, newElement, elem)
				}
			}
			GridLayoutPane: {
				newElement = createGridLayoutPaneElement(doc, viewElement)
				for (elem : viewElement.elements) {
					createChildrenElements(doc, newElement, elem)
				}
			}
			Button: {
				newElement = createButtonElement(doc, viewElement)
			}
			TextInput: {
				newElement = createTextInputElement(doc, viewElement)
			}
			Label: {
				newElement = createLabelElement(doc, viewElement)
			}
			default:
				return
		}
		element.appendChild(newElement)
	}


	protected static def createFlowLayoutPaneElement(Document doc, FlowLayoutPane flp) {
		val flowLayoutPaneElement = doc.createElement(Settings.MD2LIBRARY_VIEW_FLOWLAYOUTPANE)
		val qnp = new DefaultDeclarativeQualifiedNameProvider
		val qualifiedName = qnp.getFullyQualifiedName(flp).toString("_")

		// id
		flowLayoutPaneElement.setAttribute("android:id", "@id/" + qualifiedName)

		// height and width
		flowLayoutPaneElement.setAttribute("android:layout_width", "match_parent")
		flowLayoutPaneElement.setAttribute("android:layout_height", "wrap_content")
		flowLayoutPaneElement.setAttribute("android:layout_gravity", "fill_horizontal")

		// handle parameters
		flp.params.forEach [
			switch it {
				// orientation
				FlowLayoutPaneFlowDirectionParam case it.flowDirection == FlowDirection.VERTICAL:
					flowLayoutPaneElement.setAttribute("android:orientation", "vertical")
				FlowLayoutPaneFlowDirectionParam case it.flowDirection == FlowDirection.HORIZONTAL:
					flowLayoutPaneElement.setAttribute("android:orientation", "horizontal")
			}
		]
		return flowLayoutPaneElement
	}

	protected static def createGridLayoutPaneElement(Document doc, GridLayoutPane glp) {
		// create element
		val glpElement = doc.createElement(Settings.MD2LIBRARY_VIEW_GRIDLAYOUTPANE)		

		// assign id
		val qualifiedName = MD2AndroidLollipopUtil.getQualifiedNameAsString(glp, "_")
		glpElement.setAttribute("android:id", "@id/" + qualifiedName)

		// set default width and height
		glpElement.setAttribute("android:layout_height", "wrap_content")
		glpElement.setAttribute("android:layout_width", "match_parent")
		glpElement.setAttribute("android:layout_gravity", "fill_horizontal")
		
		// handle parameters
		glp.params.forEach [ p |
			switch p {
				// orientation
				GridLayoutPaneColumnsParam:
					glpElement.setAttribute("android:columnCount", String.valueOf(p.value))
				GridLayoutPaneRowsParam:
					glpElement.setAttribute("android:rowCount", String.valueOf(p.value))
				// width
				WidthParam:{
					glpElement.setAttribute("android:layout_columnWeight", String.valueOf(p.width))
					glpElement.getAttributeNode("android:layout_width").nodeValue = "0dp"
				}
			}
		]
		return glpElement
	}

	protected static def createButtonElement(Document doc, Button button) {
		val buttonElement = doc.createElement(Settings.MD2LIBRARY_VIEW_BUTTON)
		val qnp = new DefaultDeclarativeQualifiedNameProvider
		val qualifiedName = qnp.getFullyQualifiedName(button).toString("_")

		// id
		buttonElement.setAttribute("android:id", "@id/" + qualifiedName)

		// height and width
		if(button.width == -1){
			buttonElement.setAttribute("android:layout_width", "match_parent")
		}else{
			buttonElement.setAttribute("android:layout_width", "0dp")
			buttonElement.setAttribute("android:layout_columnWeight", String.valueOf(button.width))
		}
		
		buttonElement.setAttribute("android:layout_height", "wrap_content")
		buttonElement.setAttribute("android:layout_gravity", "fill_horizontal")

		// text
		buttonElement.setAttribute("android:text", "@string/" + qualifiedName + "_text")

		// disabled
		var isEnabled = true
		if (button.isDisabled)
			isEnabled = false

		buttonElement.setAttribute("android:enabled", String.valueOf(isEnabled))

		return buttonElement
	}

	protected static def createTextInputElement(Document doc, TextInput textInput) {
		val textInputElement = doc.createElement(Settings.MD2LIBRARY_VIEW_TEXTINPUT)
		val qnp = new DefaultDeclarativeQualifiedNameProvider
		val qualifiedName = qnp.getFullyQualifiedName(textInput).toString("_")

		// id
		textInputElement.setAttribute("android:id", "@id/" + qualifiedName)

		if(textInput.width == -1){
			textInputElement.setAttribute("android:layout_width", "match_parent")
		}else{
			textInputElement.setAttribute("android:layout_width", "0dp")
			textInputElement.setAttribute("android:layout_columnWeight", String.valueOf(textInput.width))
		}
		textInputElement.setAttribute("android:layout_height", "wrap_content")
		textInputElement.setAttribute("android:layout_gravity", "fill_horizontal")

		textInputElement.setAttribute("android:hint", "@string/" + qualifiedName + "_tooltip")

		textInputElement.setAttribute("android:text", textInput.defaultValue)
		
		// disabled
		var isEnabled = true
		if (textInput.isDisabled)
			isEnabled = false

		textInputElement.setAttribute("android:enabled", String.valueOf(isEnabled))

		// type
		switch textInput {
			case textInput.type == TextInputType.PASSWORD:
				textInputElement.setAttribute("android:inputType", "textPassword")
			case textInput.type == TextInputType.TEXTAREA:
				textInputElement.setAttribute("android:inputType",
					"text|textMultiLine")
			default:
				textInputElement.setAttribute("android:inputType", "text")
		}

		return textInputElement
	}
	
	protected static def createLabelElement(Document doc, Label label) {
		val labelElement = doc.createElement(Settings.MD2LIBRARY_VIEW_LABEL)
		val qnp = new DefaultDeclarativeQualifiedNameProvider
		val qualifiedName = qnp.getFullyQualifiedName(label).toString("_")

		// id
		labelElement.setAttribute("android:id", "@id/" + qualifiedName)

		if(label.width == -1){
			labelElement.setAttribute("android:layout_width", "match_parent")
		}else{
			labelElement.setAttribute("android:layout_width", "0dp")
			labelElement.setAttribute("android:layout_columnWeight", String.valueOf(label.width))
		}
		labelElement.setAttribute("android:layout_height", "wrap_content")
		labelElement.setAttribute("android:layout_gravity", "fill_horizontal")

		labelElement.setAttribute("android:text", "@string/" + qualifiedName + "_text")

		return labelElement
	}
}