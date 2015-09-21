package de.wwu.md2.framework.generator.ios

import de.wwu.md2.framework.generator.AbstractPlatformGenerator
import de.wwu.md2.framework.generator.IExtendedFileSystemAccess
import de.wwu.md2.framework.generator.ios.controller.IOSController
import de.wwu.md2.framework.generator.ios.model.IOSContentProvider
import de.wwu.md2.framework.generator.ios.model.IOSEntity
import de.wwu.md2.framework.generator.ios.model.IOSEnum
import de.wwu.md2.framework.generator.ios.util.FileSystemUtil
import de.wwu.md2.framework.generator.util.MD2GeneratorUtil
import de.wwu.md2.framework.mD2.SimpleType
import java.io.File
import org.eclipse.xtext.generator.IFileSystemAccessExtension2

import static de.wwu.md2.framework.generator.ios.Settings.*
import de.wwu.md2.framework.generator.ios.misc.DataModel
import de.wwu.md2.framework.generator.ios.controller.IOSCustomAction
import de.wwu.md2.framework.mD2.CustomAction
import de.wwu.md2.framework.generator.ios.workflow.IOSWorkflowEvent
import de.wwu.md2.framework.generator.ios.view.IOSWidgetMapping
import de.wwu.md2.framework.generator.ios.util.IOSGeneratorUtil
import de.wwu.md2.framework.mD2.WorkflowElement
import java.util.Collection

class IOSGenerator extends AbstractPlatformGenerator {
	
	var rootFolder = ""
	
	override doGenerate(IExtendedFileSystemAccess fsa) {
		System.out.println("START GENERATION")
		
		/***************************************************
		 * 
		 * Generate apps individually
		 * 
		 ***************************************************/
		for (app : dataContainer.apps) {
			// Folders
			val appRoot = rootFolder + "/" + app.name + "." + Settings.PLATFORM_PREFIX + "/"
			val mainPackage = MD2GeneratorUtil.getBasePackageName(processedInput).replace("^/", ".").toLowerCase
			rootFolder = appRoot + mainPackage.replace(".", "/") + "/"
			Settings.ROOT_FOLDER = rootFolder
			IOSGeneratorUtil.printDebug("Generate App: " + rootFolder, true)

			// Copy static part in target folder
			val resourceFolderAbsolutePath = getClass().getResource("/resources/" 
				+ Settings.PLATFORM_PREFIX + "/" + Settings.STATIC_CODE_PATH);
			val targetFolderAbsolutePath = (fsa as IFileSystemAccessExtension2).getURI(rootFolder).toFileString()
			
			FileSystemUtil.createParentDirs(new File(targetFolderAbsolutePath)) // ensure path exists
			
			IOSGeneratorUtil.printDebug("Copy library files with static code:")
			IOSGeneratorUtil.printDebug(FileSystemUtil.copyDirectory(
				new File(resourceFolderAbsolutePath.toURI()),
				new File(targetFolderAbsolutePath)).map[elem | 
					elem.replace(targetFolderAbsolutePath, "").replace("\\","/")
				].join("\n"))
			
			/***************************************************
			 * 
			 * Misc 
			 * Data model and project file
			 * 
			 ***************************************************/
			// Generate data model for local storage
			val entities = dataContainer.entities
			val pathDataModel = rootFolder + Settings.MODEL_PATH 
				+ "datastore/LocalData.xcdatamodeld/LocalData.xcdatamodel/contents"
			fsa.generateFile(pathDataModel, DataModel.generateClass(entities))
			
			// Project file
			// TODO Project file
			
			/***************************************************
			 * 
			 * Model
			 * 
			 ***************************************************/
			IOSGeneratorUtil.printDebug("Generate Model: " + rootFolder + Settings.MODEL_PATH, true)
			 
			// Generate all model entities
			entities.forEach [entity | 
				val path = rootFolder + Settings.MODEL_PATH + "entity/" 
					+ Settings.PREFIX_ENTITY + entity.name.toFirstUpper + ".swift"
				IOSGeneratorUtil.printDebug("Generate entity: " + entity.name.toFirstUpper, path)
				fsa.generateFile(path, IOSEntity.generateClass(entity))
			]
			
			// Generate all model enums
			dataContainer.enums.forEach [enum | 
				val path = rootFolder + Settings.MODEL_PATH + "enum/" 
					+ Settings.PREFIX_ENUM + enum.name.toFirstUpper + ".swift"
				IOSGeneratorUtil.printDebug("Generate entity: " + enum.name.toFirstUpper, path)
				fsa.generateFile(path, IOSEnum.generateClass(enum))
			]
			
			// Generate content providers
			dataContainer.contentProviders.forEach [ cp |
				val path = rootFolder + Settings.MODEL_PATH + "contentProvider/"  
					+ Settings.PREFIX_CONTENT_PROVIDER + cp.name.toFirstUpper + ".swift"
				
				// TODO ContentProvider for simple data type -> what is this for?
				if (cp.type instanceof SimpleType) {
					IOSGeneratorUtil.printError("SimpleType unsupported in ContentProvider!")
				} else {
					IOSGeneratorUtil.printDebug("Generate content provider: " 
						+ cp.name.toFirstUpper, path)
					fsa.generateFile(path, IOSContentProvider.generateClass(cp))
				}
			]
			
			/***************************************************
			 * 
			 * View
			 * 
			 ***************************************************/
			IOSGeneratorUtil.printDebug("Generate Views: " + rootFolder 
				+ Settings.VIEW_PATH, true)
				
			// Generate WidgetMapping
			/* iOS specific class because widgets cannot pass any information
			 * on event triggering except for an integer value. This iOS-enum
			 * provides the mapping between a view element and such a value 
			 * for identification in the event handlers.
			 */
			val pathWidgetMapping = rootFolder + Settings.VIEW_PATH 
				+ Settings.PREFIX_GLOBAL + "WidgetMapping.swift"
			IOSGeneratorUtil.printDebug("Generate view mapping", pathWidgetMapping)
			fsa.generateFile(pathWidgetMapping, IOSWidgetMapping.generateClass(dataContainer.view))

			/***************************************************
			 * 
			 * Controller
			 * 
			 ***************************************************/
		 	IOSGeneratorUtil.printDebug("Generate Controller: " + rootFolder 
			 	+ Settings.CONTROLLER_PATH, true)
			 
			dataContainer.workflowElements.forEach [wfe | 
			 	wfe.actions.filter(CustomAction).forEach[ ca |
			 		val path = rootFolder + Settings.CONTROLLER_PATH + "action/" 
						+ Settings.PREFIX_CUSTOM_ACTION 
						+ MD2GeneratorUtil.getName(ca).toFirstUpper + ".swift"
					IOSGeneratorUtil.printDebug("Generate custom action: " 
						+ MD2GeneratorUtil.getName(ca), path)
					fsa.generateFile(path, IOSCustomAction.generateClass(ca))
			 	]
			]
			 
			val pathMainController = rootFolder + Settings.CONTROLLER_PATH 
				+ Settings.PREFIX_GLOBAL + "Controller.swift"
			IOSGeneratorUtil.printDebug("Generate main controller: " 
				+ pathMainController, false)
			fsa.generateFile(pathMainController, IOSController.generateStartupController(dataContainer, app))
			
			/***************************************************
			 * 
			 * Workflow
			 * 
			 ***************************************************/
			IOSGeneratorUtil.printDebug("Generate Workflows: " + rootFolder 
			 	+ Settings.WORKFLOW_PATH, true)
			
			val pathWorkflowEvents = rootFolder + Settings.WORKFLOW_PATH 
				+ Settings.PREFIX_GLOBAL + "WorkflowEvent.swift"
			IOSGeneratorUtil.printDebug("Generate workflow events", pathWorkflowEvents) 		
 		 	fsa.generateFile(pathWorkflowEvents, IOSWorkflowEvent.generateClass(dataContainer))
		}

		println("\nIOS GENERATION COMPLETED\n")
	}

	override getPlatformPrefix() {
		Settings.PLATFORM_PREFIX
	}
}