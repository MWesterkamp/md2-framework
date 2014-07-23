package de.wwu.md2.framework.generator.mapapps

import de.wwu.md2.framework.generator.util.DataContainer
import de.wwu.md2.framework.mD2.AlternativesPane
import de.wwu.md2.framework.mD2.BooleanInput
import de.wwu.md2.framework.mD2.Button
import de.wwu.md2.framework.mD2.DateInput
import de.wwu.md2.framework.mD2.DateTimeInput
import de.wwu.md2.framework.mD2.EntitySelector
import de.wwu.md2.framework.mD2.GridLayoutPane
import de.wwu.md2.framework.mD2.GridLayoutPaneColumnsParam
import de.wwu.md2.framework.mD2.HexColorDef
import de.wwu.md2.framework.mD2.Image
import de.wwu.md2.framework.mD2.IntegerInput
import de.wwu.md2.framework.mD2.Label
import de.wwu.md2.framework.mD2.NumberInput
import de.wwu.md2.framework.mD2.OptionInput
import de.wwu.md2.framework.mD2.Spacer
import de.wwu.md2.framework.mD2.StyleAssignment
import de.wwu.md2.framework.mD2.StyleDefinition
import de.wwu.md2.framework.mD2.TabbedAlternativesPane
import de.wwu.md2.framework.mD2.TextInput
import de.wwu.md2.framework.mD2.TimeInput
import de.wwu.md2.framework.mD2.Tooltip
import de.wwu.md2.framework.mD2.ViewGUIElement
import de.wwu.md2.framework.mD2.WidthParam
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.xbase.lib.Pair

import static extension de.wwu.md2.framework.generator.util.MD2GeneratorUtil.*
import static extension de.wwu.md2.framework.util.StringExtensions.*

class ManifestJson {
	
	def static generateManifestJson(DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"Bundle-SymbolicName": "md2_«processedInput.getBasePackageName.split("\\.").reduce[ s1, s2 | s1 + "_" + s2]»",
			"Bundle-Version": "«dataContainer.main.appVersion»",
			"Bundle-Name": "«dataContainer.main.appName»",
			"Bundle-Description": "Generated MD2 bundle: «dataContainer.main.appName»",
			"Bundle-Localization": [],
			"Bundle-Main": "",
			"Require-Bundle": [],
			"Components": [
				«val snippets = newArrayList(
					generateConfigurationSnippet(dataContainer, processedInput),
					generateCustomActionsSnippet(dataContainer, processedInput),
					generateEntitiesSnippet(dataContainer, processedInput),
					generateContentProvidersSnippet(dataContainer, processedInput),
					generateControllerSnippet(dataContainer, processedInput),
					generateToolSnippet(dataContainer, processedInput)
				)»
				«FOR snippet : snippets.filter(s | !s.toString.trim.empty) SEPARATOR ","»
					«snippet»
				«ENDFOR»
			]
		}
	'''
	
	def private static String generateConfigurationSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"name": "MD2«processedInput.getBasePackageName.split("\\.").last.toFirstUpper»",
			"impl": "ct/Stateful",
			"provides": ["md2.app.«processedInput.getBasePackageName».AppDefinition"],
			"propertiesConstructor": true,
			"properties": {
				"id": "md2_«processedInput.getBasePackageName.replace(".", "_")»",
				"windowTitle": "«dataContainer.main.appName»",
				"onInitialized": "«dataContainer.main.onInitializedEvent.name»",
				"views": [
					«FOR view : dataContainer.rootViewContainers SEPARATOR ","»
						{
							"name": "«view.name»",
							"dataForm": {
								"dataform-version": "1.0.0",
								"size": {
									"h": "400",
									"w": "550"
								},
								«getViewElement(view)»
							}
						}
					«ENDFOR»
				]
			}
		}
	'''
	
	def static generateCustomActionsSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		«FOR customAction : dataContainer.customActions SEPARATOR ","»
			{
				"name": "«customAction.name.toFirstUpper»Action",
				"impl": "./actions/«customAction.name.toFirstUpper»",
				"provides": ["md2.app.«processedInput.getBasePackageName».CustomAction"]
			}
		«ENDFOR»
	'''
	
	def static generateEntitiesSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		«FOR entity : dataContainer.entities SEPARATOR ","»
			{
				"name": "«entity.name.toFirstUpper»Entity",
				"impl": "./entities/«entity.name.toFirstUpper»",
				"provides": ["md2.app.«processedInput.getBasePackageName».Entity"]
			}
		«ENDFOR»
	'''
	
	def static generateContentProvidersSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		«FOR contentProvider : dataContainer.contentProviders SEPARATOR ","»
			{
				"name": "«contentProvider.name.toFirstUpper»Provider",
				"impl": "./contentproviders/«contentProvider.name.toFirstUpper»",
				"provides": ["md2.app.«processedInput.getBasePackageName».ContentProvider"],
				«IF !contentProvider.local»
					"propertiesConstructor": true,
					"properties": {
						"uri": "«IF contentProvider.^default»«dataContainer.main.defaultConnection.uri»«ELSE»«contentProvider.connection.uri»«ENDIF»"
					},
				«ENDIF»
				"references": [
					{
						«IF contentProvider.local»
							"name": "_localFactory",
							"providing": "md2.store.LocalStore",
						«ELSE»
							"name": "_remoteFactory",
							"providing": "md2.store.RemoteStore",
						«ENDIF»
						"cardinality": "0..1"
					}
				]
			}
		«ENDFOR»
	'''
	
	def static generateControllerSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"name": "Controller",
			"provides": ["md2.app.«processedInput.getBasePackageName».Controller"],
			"instanceFactory": true,
			"references": [
				{
					"name": "_md2AppWidget",
					"providing": "md2.runtime.InstanceFactory"
				},
				{
					"name": "_customActions",
					"providing": "md2.app.«processedInput.getBasePackageName».CustomAction",
					"cardinality": "0..n"
				},
				{
					"name": "_entities",
					"providing": "md2.app.«processedInput.getBasePackageName».Entity",
					"cardinality": "0..n"
				},
				{
					"name": "_contentProviders",
					"providing": "md2.app.«processedInput.getBasePackageName».ContentProvider",
					"cardinality": "0..n"
				},
				{
					"name": "_configBean",
					"providing": "md2.app.«processedInput.getBasePackageName».AppDefinition"
				}
			]
		}
	'''
	
	def static generateToolSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"name": "MD2«processedInput.getBasePackageName.split("\\.").last.toFirstUpper»Tool",
			"impl": "ct.tools.Tool",
			"provides": ["ct.tools.Tool"],
			"propertiesConstructor": true,
			"properties": {
				"id": "md2_«processedInput.getBasePackageName.replace(".", "_")»_tool",
				"title": "«dataContainer.main.appName»",
				"description": "Start «dataContainer.main.appName»",
				"tooltip": "Start «dataContainer.main.appName»",
				"toolRole": "toolset",
				"iconClass": "icon-view-grid",
				"togglable": true,
				"activateHandler": "openWindow",
				"deactivateHandler": "closeWindow"
			},
			"references": [
				{
					"name": "handlerScope",
					"providing": "md2.app.«processedInput.getBasePackageName».Controller"
				}
			]
		}
	'''
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	// Dispatch: All ViewGUIElements
	////////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * TODO If there is a warning "Cannot infer type from recursive usage. Type 'Object' is used.", this is related to
	 *      Eclipse Bug 404817 (https://bugs.eclipse.org/bugs/show_bug.cgi?id=404817).
	 *      This todo can be removed when the bug is fixed! Until then the return type String has to be specified
	 *      explicitly.
	 */
	 
	
	/***************************************************************
	 * Container Elements
	 ***************************************************************/
	
	def private static dispatch String getViewElement(GridLayoutPane gridLayout) '''
		"type": "md2gridpanel",
		"cols": "«gridLayout.params.filter(typeof(GridLayoutPaneColumnsParam)).head.value»",
		"valueClass": "layoutCell",
		«generateStyle(null, "width" -> '''«gridLayout.params.filter(typeof(WidthParam)).head.width»%''')»,
		"children": [
			«FOR element : gridLayout.elements.filter(typeof(ViewGUIElement)) SEPARATOR ","»
				{
					«getViewElement(element)»
				}
			«ENDFOR»
		]
	'''
	
	def private static dispatch String getViewElement(TabbedAlternativesPane tabbedPane) '''
		// TODO
	'''
	
	def private static dispatch String getViewElement(AlternativesPane alternativesPane) '''
		// TODO
	'''
	
	
	/***************************************************************
	 * Content Elements => Various
	 ***************************************************************/
	 
	 def private static dispatch String getViewElement(Image image) '''
		// TODO
	'''
	
	def private static dispatch String getViewElement(Spacer spacer) '''
		"type": "spacer",
		«generateStyle(null, "width" -> '''«spacer.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Button button) '''
		"type": "button",
		"title": "«button.text.escape»",
		"field": "«getName(button)»",
		«generateStyle(button.style, "width" -> '''«button.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Label label) '''
		"type": "textoutput",
		"datatype": "string",
		"field": "«getName(label)»",
		"defaultText": "«label.text.escape»",
		«generateStyle(label.style, "width" -> '''«label.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Tooltip tooltip) '''
		// TODO
	'''
	
	
	/***************************************************************
	 * Content Elements => Input
	 ***************************************************************/
	
	def private static dispatch String getViewElement(BooleanInput input) '''
		"type": "checkbox",
		"datatype": "boolean",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(TextInput input) '''
		"type": "textbox",
		"datatype": "string",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(IntegerInput input) '''
		"type": "numberspinner",
		"datatype": "integer",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(NumberInput input) '''
		"type": "numbertextbox",
		"datatype": "float",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(DateInput input) '''
		"type": "datetextbox",
		"datatype": "date",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(TimeInput input) '''
		"type": "timetextbox",
		"datatype": "time",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(DateTimeInput input) '''
		// TODO
	'''
	
	def private static dispatch String getViewElement(OptionInput input) '''
		"type": "selectbox",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(EntitySelector input) '''
		// TODO
	'''
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	// Generate Styles
	////////////////////////////////////////////////////////////////////////////////////////////
	
	def private static generateStyle(StyleAssignment styleAssignment, Pair<String, String>... additionalValues) {
		
		val values = newArrayList(additionalValues)
		
		// all style references were replaced by the actual definitions during pre-processing
		val style = (styleAssignment as StyleDefinition)?.definition
		
		if (style != null && style.bold) {
			values.add("font-weight" -> "bold")
		}
		
		if (style != null && style.italic) {
			values.add("font-style" -> "italic")
		}
		
		if (style?.color != null) {
			// after pre-processing all colors are in hex format
			values.add("color" -> (style.color as HexColorDef).color)
		}
		
		if (style != null && style.fontSize != 0d) {
			values.add("font-size" -> '''«style.fontSize»em''')
		}
		
		'''
			"cellStyle": {
				«FOR value : values SEPARATOR ","»
					"«value.key»": "«value.value»"
				«ENDFOR»
			}
		'''
	}
	
}