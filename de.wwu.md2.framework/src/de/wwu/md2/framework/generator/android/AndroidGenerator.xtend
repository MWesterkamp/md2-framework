package de.wwu.md2.framework.generator.android

import de.wwu.md2.framework.generator.AbstractPlatformGenerator
import de.wwu.md2.framework.generator.IExtendedFileSystemAccess
import de.wwu.md2.framework.generator.android.templates.StringsXmlTemplate
import de.wwu.md2.framework.generator.android.util.JavaClassDef
import de.wwu.md2.framework.mD2.ContainerElement
import de.wwu.md2.framework.mD2.Enum
import de.wwu.md2.framework.mD2.ModelElement
import de.wwu.md2.framework.mD2.TabbedAlternativesPane
import java.util.List
import java.util.Queue
import java.util.Set
import org.eclipse.emf.ecore.resource.ResourceSet

import static com.google.common.collect.Lists.*
import static de.wwu.md2.framework.generator.android.ArraysXml.*
import static de.wwu.md2.framework.generator.android.ModelClass.*
import static de.wwu.md2.framework.generator.android.StyleXml.*
import static de.wwu.md2.framework.generator.android.common.DotClassPath.*
import static de.wwu.md2.framework.generator.android.common.DotProject.*
import static de.wwu.md2.framework.generator.android.common.Manifest.*
import static de.wwu.md2.framework.generator.android.common.Preferences.*
import static de.wwu.md2.framework.generator.android.common.ProjectProperties.*
import static de.wwu.md2.framework.generator.android.util.MD2AndroidUtil.*
import static de.wwu.md2.framework.generator.util.MD2GeneratorUtil.*
import static de.wwu.md2.framework.util.MD2Util.*
import de.wwu.md2.framework.mD2.ViewElementType
import de.wwu.md2.framework.mD2.ViewElementRef
import de.wwu.md2.framework.mD2.ViewElementDef
import de.wwu.md2.framework.mD2.GridLayoutPane
import de.wwu.md2.framework.mD2.FlowLayoutPane
import de.wwu.md2.framework.mD2.Listtype

/**
 * Android platform generator
 */
class AndroidGenerator extends AbstractPlatformGenerator {
	
	int minAppVersion = 11
	
	override doGenerate(ResourceSet input, IExtendedFileSystemAccess fsa) {
		
		super.doGenerate(input, fsa)
		
		
		/////////////////////////////////////////
		// Feasibility check
		/////////////////////////////////////////
		
		// Check whether a main block has been defined. Otherwise do not run the generator.
		if(dataContainer.main == null) {
			System::out.println("Android: No main block found. Quit gracefully.")
			return
		}
		
		
		/////////////////////////////////////////
		// Generation work flow
		/////////////////////////////////////////
		
		// Clean Android folder
		fsa.deleteDirectory(basePackageName)
		
		// Copy resources
		fsa.copyFileFromProject("resources/images", basePackageName + "/res/drawable-xhdpi")
		
		// Copy static library files
		fsa.generateFileFromInputStream(getSystemResource("/android/guava-10.0.1.jar"), basePackageName + "/lib/guava-10.0.1.jar")
		fsa.generateFileFromInputStream(getSystemResource("/android/md2-android-lib.jar"), basePackageName + "/lib/md2-android-lib.jar")
		fsa.generateFileFromInputStream(getSystemResource("/android/jackson-all-1.9.9.jar"), basePackageName + "/lib/jackson-all-1.9.9.jar")
		
		
		// Copy Icons and logos
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-ldpi/ic_launcher.png"), basePackageName + "/res/drawable-ldpi/ic_launcher.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-mdpi/ic_launcher.png"), basePackageName + "/res/drawable-mdpi/ic_launcher.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-hdpi/ic_launcher.png"), basePackageName + "/res/drawable-hdpi/ic_launcher.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-xhdpi/ic_launcher.png"), basePackageName + "/res/drawable-xhdpi/ic_launcher.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-ldpi/information.png"), basePackageName + "/res/drawable-hdpi/information.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-mdpi/information_24px.png"), basePackageName + "/res/drawable-ldpi/information.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-hdpi/information_32px.png"), basePackageName + "/res/drawable-mdpi/information.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/drawable-xhdpi/information_32px.png"), basePackageName + "/res/drawable-xhdpi/information.png")
		fsa.generateFileFromInputStream(getSystemResource("/android/layout/checkboxlist.xml"), basePackageName + "/res/layout/checkboxlist.xml")
		
		// Generate common base elements
		fsa.generateFile(basePackageName + "/.project", dotProject(basePackageName))
		fsa.generateFile(basePackageName + "/.classpath", dotClassPath)
		fsa.generateFile(basePackageName + "/project.properties", projectProperties(minAppVersion))
		fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + "/" + createAppClassName(dataContainer) + ".java", ProjectApplication::generateApplication(basePackageName, createAppClassName(dataContainer), dataContainer))
		fsa.generateFile(basePackageName + "/.settings/org.eclipse.core.resources.prefs", preferences)
		
		
		/////////////////////////////////////////
		// Generate models
		/////////////////////////////////////////
		
		// Generate models and create list of all enumerations
		val Iterable<Enum> enums = dataContainer.models.map(model | model.modelElements.filter(typeof(Enum))).flatten
		dataContainer.models.forEach[model | model.modelElements.forEach[elem | createModel(fsa, elem)]]
		
		// Generate Arrays.xml
		fsa.generateFile(basePackageName + "/res/values/arrays.xml" , generateArraysXml(enums))
		val stringsTemplate = new StringsXmlTemplate();
		stringsTemplate.addString("app_name", dataContainer.main.appName)
		
		
		/////////////////////////////////////////
		// Generate views
		/////////////////////////////////////////
		
		// Generate Style.xml
		fsa.generateFile(basePackageName + "/res/values/style.xml" , generateStyleXml())
		
		// List of all root views that will be created
		val Set<ContainerElement> activities = newHashSet
		// Insert all view containers not contained in an (tabbed) alternatives pane
		activities.addAll(dataContainer.viewContainersNotInAnyAlternativesPane)
		
		// List of all sub views (contained in a tabbed pane or an alternatives pane)
		val Set<ContainerElement> fragments = newHashSet
		// Insert all view containers contained in an alternatives pane
		fragments.addAll(dataContainer.viewContainersInAnyAlternativesPane)
		
		// Initialize queue to generate all already know view containers
		// and so far unknow view containers that might be contained in sub alternatives pane
		val Queue<ContainerElement> viewContainerQueue = newLinkedList
		viewContainerQueue.addAll(dataContainer.viewContainers)
		
		// Check if the tabbed alternatives pane is already in the list of activities and add it otherwise
		if(dataContainer.tabbedAlternativesPane != null) {
			activities.add(dataContainer.tabbedAlternativesPane)
		}
		
		while(!viewContainerQueue.isEmpty()) {
			val curViewContainer = viewContainerQueue.remove
			// Generate view
			if(!(curViewContainer instanceof TabbedAlternativesPane)) {
				val viewGenerator = new LayoutXml(stringsTemplate)
				fsa.generateFile(basePackageName + "/res/layout/" + getName(curViewContainer).toLowerCase + ".xml" , viewGenerator.generateLayoutXml(curViewContainer))
				// Add all new detected fragments to the queue and the list of fragments
				viewContainerQueue.addAll(viewGenerator.newFragmentsToGenerate)
				fragments.addAll(viewGenerator.newFragmentsToGenerate)
			}
		}
		
		
		/////////////////////////////////////////
		// Generate controllers
		/////////////////////////////////////////
		
		val Set<ContainerElement> topLevelViewContainers = newHashSet
		topLevelViewContainers.addAll(activities)
		topLevelViewContainers.addAll(fragments)
		
		// Determine main activity
		val ContainerElement mainActivity = if(activities.contains(resolveContainerElement(dataContainer.main.startView))) {
			resolveContainerElement(dataContainer.main.startView)
		}
		else if(dataContainer.tabbedViewContent.contains(resolveContainerElement(dataContainer.main.startView))) {
			dataContainer.tabbedAlternativesPane
		}
		else {
			throw new Exception("Android: Cannot determine main activity")
		}
		
		// Generate actions
		dataContainer.customActions.forEach [
			fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + "/actions/" + getName(it).toFirstUpper + ".java", 
				new CustomActionTemplate(basePackageName, it, dataContainer, topLevelViewContainers, activities, fragments).generateCustomAction
			)
		]
		
		// Generate conditions
		dataContainer.conditions.forEach[conditionName, condition |
			val conditionGenerator = new ConditionClass(dataContainer, topLevelViewContainers)
			writeJavaFile(fsa, createJavaClassDef("condition", [it.simpleName = conditionName
																conditionGenerator.generateCondition(it, condition)
			]))
		]
		
		// Generate workflows and workflow steps
		dataContainer.workflows.forEach[workflow |
			val workflowGenerator = new WorkflowClass(dataContainer)
			writeJavaFile(fsa, createJavaClassDef("workflow", [it.simpleName = workflow.name.toFirstUpper
																workflowGenerator.generateWorkflow(it, workflow)
			]))
			workflow.workflowSteps.forEach[workflowStep |
				writeJavaFile(fsa, createJavaClassDef("workflow", [it.simpleName = workflowStep.name.toFirstUpper
																	workflowGenerator.generateWorkflowStep(it, workflowStep, activities, fragments)
				]))
			]
		]
		
		// Generate activities
		val activityGenerator = new Activity(dataContainer)
		activities.forEach [
			if(it instanceof TabbedAlternativesPane) {
				fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + "/controller/" + getName(it).toFirstUpper + "Activity.java" , activityGenerator.generateTabbedActivity(basePackageName, stringsTemplate, it as TabbedAlternativesPane))
			}
			else {
				fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + "/controller/" + getName(it).toFirstUpper + "Activity.java" , activityGenerator.generateActivity(basePackageName, it, dataContainer))
			}
		]
		
		// Generate fragments
		fragments.forEach [ fragment |
			writeJavaFile(fsa, createJavaClassDef("controller", [activityGenerator.generateFragment(it, fragment)]))
		]
		
		fragments.forEach[fragment |
			getElements(fragment).forEach[viewElemType|
				if(getViewGUIElement(viewElemType) instanceof de.wwu.md2.framework.mD2.List && (getViewGUIElement(viewElemType) as de.wwu.md2.framework.mD2.List).listtype.value.equals(Listtype::CHECKBOX_VALUE)){
					fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + "/adapter/" + "CheckboxAdapter.java" , new CheckboxList().generateCheckboxList(basePackageName, getViewGUIElement(viewElemType), dataContainer));	
				}
			]
		]

		
		// Generate content providers
		dataContainer.contentProviders.forEach [
			val template = new ContentProviderClass(dataContainer, mainActivity, it)
//			if (it.local) {
				writeJavaFile(fsa, createJavaClassDef("contentprovider", [template.generateContentProvider(it)]))
//			} else {
			// TODO Generate remote ContentProvider class
//			}
		]
		
		
		/////////////////////////////////////////
		// Generate general files
		/////////////////////////////////////////
		
		val List<ContainerElement> activitiesListForFragment = newLinkedList
		activitiesListForFragment.addAll(activities)
		activitiesListForFragment.remove(mainActivity)
		activitiesListForFragment.add(0, mainActivity)
		
		// Generate Manifest
		fsa.generateFile(basePackageName + "/AndroidManifest.xml", manifest(basePackageName, minAppVersion, dataContainer, activitiesListForFragment))
		
		// Generate from template objects
		fsa.generateFile(basePackageName + "/res/values/strings.xml" , stringsTemplate.render())
	}
	
	def private createModel(IExtendedFileSystemAccess fsa, ModelElement elem) {
		try {
			fsa.generateFile(basePackageName + "/src/" + basePackageName.replace('.', '/') + '/models/' + elem.name + '.java' , createClass(elem, basePackageName))
		} catch (Exception e) {
			System::out.println("Error generating model class " + elem.name + ". Type: " + elem.toString() + " (" + e.getClass().name + ": " + e.message+")");
		}
	}
	
	override getPlatformPrefix() {
		"android"
	}
	
	/**
	 * Helper to create a java file descriptor.
	 * 
	 * @param initializer Function to initialize the file descriptor. It's return value will be used as the file content.
	 * 
	 * Example:
	 * writeJavaFile(fsa, [it.baseName = "de.test"; it.simpleName = "HelloWorld"; generateHelloWorld(it)])
	 */
	def private JavaClassDef createJavaClassDef(String subPackage, (JavaClassDef)=>CharSequence initializer) {
		val classDef = new JavaClassDef()
		classDef.basePackage = basePackageName
		classDef.subPackage = subPackage
		classDef.contents = initializer.apply(classDef)
		return classDef
	}
	
	
	
		/////////////////////////////////////////
	// Helper methods
	/////////////////////////////////////////
	
	
	def private getViewGUIElement(ViewElementType viewElemType) {
		switch viewElemType {
			ViewElementRef: viewElemType.value
			ViewElementDef: viewElemType.value
		}
	}
	
	/**
	 * Returns an EList containing all content elements of a container.
	 */
	def private static getElements(ContainerElement e)
	{
		switch e
		{
			GridLayoutPane: e.elements
			FlowLayoutPane: e.elements
		}
	}
	
}
