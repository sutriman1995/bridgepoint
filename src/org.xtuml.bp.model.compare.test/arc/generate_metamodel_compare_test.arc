.function generate_class_header
//========================================================================
//
// File: <complete_generated_file_path>.java
//
// WARNING:      Do not edit this generated file
// Generated by: ${info.arch_file_name}
// Version:      $$Revision: 1.7.8.2 $$
//
// Copyright 2005-2014 Mentor Graphics Corporation.  All rights reserved.
//
//========================================================================
// Licensed under the Apache License, Version 2.0 (the "License"); you may not 
// use this file except in compliance with the License.  You may obtain a copy 
// of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   See the 
// License for the specific language governing permissions and limitations under
// the License.
//======================================================================== 
package org.xtuml.bp.model.compare.test;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Iterator;
import java.util.Set;

import org.eclipse.compare.internal.CompareEditor;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.team.internal.ui.actions.CompareAction;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.PlatformUI;

import org.xtuml.bp.core.*;
import org.xtuml.bp.core.common.ClassQueryInterface_c;
import org.xtuml.bp.core.common.ModelRoot;
import org.xtuml.bp.core.common.NonRootModelElement;
import org.xtuml.bp.core.common.PersistableModelComponent;
import org.xtuml.bp.core.common.Transaction;
import org.xtuml.bp.core.common.TransactionException;
import org.xtuml.bp.core.common.TransactionManager;
import org.xtuml.bp.core.inspector.ObjectElement;
import org.xtuml.bp.core.util.WorkspaceUtil;
import org.xtuml.bp.model.compare.ComparableTreeObject;
import org.xtuml.bp.model.compare.TreeDifference;
import org.xtuml.bp.model.compare.TreeDifferencer;
import org.xtuml.bp.model.compare.providers.NonRootModelElementComparable;
import org.xtuml.bp.test.common.BaseTest;
import org.xtuml.bp.ui.canvas.Fillcolorstyle_c;
import org.xtuml.bp.ui.canvas.FloatingText_c;
import org.xtuml.bp.ui.canvas.Graphconnector_c;
import org.xtuml.bp.ui.canvas.Graphelement_c;
import org.xtuml.bp.ui.canvas.Graphnode_c;
import org.xtuml.bp.ui.canvas.Layer_c;
import org.xtuml.bp.ui.canvas.Linecolorstyle_c;
import org.xtuml.bp.ui.canvas.Model_c;
import org.xtuml.bp.ui.canvas.Ooaofgraphics;
import org.xtuml.bp.ui.canvas.Waypoint_c;

public class ModelComparisonTests extends BaseTest {

	private static String modifyString = "_modified";
	
		@Override
	public void initialSetup() throws CoreException, IOException {
		// load test model 
		WorkspaceUtil.setAutobuilding(false);

		final IProject project = ResourcesPlugin.getWorkspace().getRoot()
				..getProject("HierarchyTestModel");

		loadProject("HierarchyTestModel");
		
		m_sys = SystemModel_c.SystemModelInstance(Ooaofooa
				..getDefaultInstance(), new ClassQueryInterface_c() {

			public boolean evaluate(Object candidate) {
				return ((SystemModel_c) candidate).getName().equals(
						project.getName());
			}

		});
		PersistableModelComponent sys_comp = m_sys
				..getPersistableComponent();
		sys_comp.loadComponentAndChildren(new NullProgressMonitor());
	}
	
.end function
.function generate_helper_methods
	@SuppressWarnings("restriction")
	private TreeDifferencer compareElementWithLocalHistory(NonRootModelElement instance, IFile copy) {
		IFile file = instance.getFile();
		CompareAction action = new CompareAction();
		action.selectionChanged(null, new StructuredSelection(new Object[] {
				file, copy }));
		action.run(null);
		IEditorPart activeEditor = PlatformUI.getWorkbench()
				..getActiveWorkbenchWindow().getActivePage().getActiveEditor();
		assertTrue("Unable to locate compare editor.", activeEditor instanceof CompareEditor);
		while(PlatformUI.getWorkbench().getDisplay().readAndDispatch());
		Set<Object> keySet = TreeDifferencer.instances.keySet();
		Object key = null;
		for(Iterator<Object> iterator = keySet.iterator(); iterator.hasNext();) {
			key = iterator.next();
		}
		return TreeDifferencer.instances.get(key);
	}
	
	private void performTest(NonRootModelElement instance, String methodName,
			String modelPath, Object newValue) throws SecurityException,
			NoSuchMethodException, CoreException, IllegalArgumentException,
			IllegalAccessException, InvocationTargetException {
		IFile copy = null;
		Transaction transaction = null;
		try {
			instance.getFile().copy(
					new Path("/" + instance.getFile().getProject().getName() + "/"
							+ instance.getFile().getName()), true,
					new NullProgressMonitor());
			copy = instance.getFile().getProject().getFile(
					instance.getFile().getName());
			TransactionManager manager = TransactionManager.getSingleton();
				transaction = manager.startTransaction(
						"Modify attribute value for " + modelPath, new ModelRoot[] {
								Ooaofooa.getDefaultInstance(),
								Ooaofgraphics.getDefaultInstance() });
				Method[] methods = instance.getClass().getMethods();
				for(Method method : methods) {
					if(method.getName().equals(methodName)) {
						method.invoke(instance, new Object[] { newValue });
						break;
					}
				}
				manager.endTransaction(transaction);
			TreeDifferencer differencer = compareElementWithLocalHistory(instance,
					copy);
			assertTrue("No differences found for attribute value modification: "
					+ modelPath, differencer.getLeftDifferences().size() != 0);
			assertTrue(
					"More differences found for attribute value modification than expected.",
					differencer.getLeftDifferences().size() == getExpectedSizeForChange(differencer, instance));
			if(getExpectedSizeForChange(differencer, instance) == 1) {
				assertTrue(
						"Invalid difference type found for attribute value modification.",
						differencer.getLeftDifferences().get(0).getType() == TreeDifference.VALUE_DIFFERENCE);
			}
		} catch(Exception e) {
			if(transaction != null) {
				TransactionManager.getSingleton().cancelTransaction(transaction);
			}
			fail("Unable to modify attribute value.");
		} finally {
			// undo the change
			if(transaction != null) {
				TransactionManager.getSingleton().getUndoAction().run();
			}
			// remove copy
			if(copy != null) {
				copy.delete(true, new NullProgressMonitor());
			}
			PlatformUI.getWorkbench().getActiveWorkbenchWindow().getActivePage().closeAllEditors(false);
			while(PlatformUI.getWorkbench().getDisplay().readAndDispatch());
		}
	}

	private int getExpectedSizeForChange(TreeDifferencer differencer, Object testElement) {
		if(getName().contains("Layer_Name")) {
			return 2;
		}
		if(differencer.getLeftDifferences().size() == 2) {
			// this could be rename, where the differences
			// are shown both for the attribute and the root
			// element
			for(TreeDifference difference : differencer.getLeftDifferences()) {
				if(difference.getType().equals(TreeDifference.VALUE_DIFFERENCE)) {
					ComparableTreeObject comparable = (ComparableTreeObject) difference.getElement();
					if(comparable.getRealElement() instanceof ObjectElement) {
						ObjectElement obEle = (ObjectElement) comparable.getRealElement();
						ComparableTreeObject one = new NonRootModelElementComparable((NonRootModelElement) testElement);
						ComparableTreeObject two = new NonRootModelElementComparable((NonRootModelElement) obEle.getParent());
						if(one.equals(two)) {
							return 2;
						} else {
							return 1;
						}
					} else {
						return 1;
					}
				}
				if(difference.getType().equals(TreeDifference.NAME_DIFFERENCE)) {
					continue;
				} else {
					return 1;
				}
			}
		} else if(differencer.getLeftDifferences().size() == 3) {
			int count = 0;
			for(TreeDifference difference : differencer.getLeftDifferences()) {
				if(difference.getType().equals(TreeDifference.VALUE_DIFFERENCE)) {
					ComparableTreeObject comparable = (ComparableTreeObject) difference.getElement();
					if(comparable.getRealElement() instanceof ObjectElement) {
						ObjectElement obEle = (ObjectElement) comparable.getRealElement();
						ComparableTreeObject one = new NonRootModelElementComparable((NonRootModelElement) testElement);
						ComparableTreeObject two = new NonRootModelElementComparable((NonRootModelElement) obEle.getParent());
						if(one.equals(two)) {
							if(count == 1) {
								count++;
								continue;
							} else if(count == 2) {
								return 3;
							}
						} else {
							return 1;
						}
					} else {
						return 1;
					}
				}
				if(difference.getType().equals(TreeDifference.NAME_DIFFERENCE)) {
					count++;
					continue;
				} else {
					return 1;
				}
			}
		}
		return 1;
	}
.end function
.function get_set_value
  .param inst_ref attribute
    .select one dt related by attribute->S_DT[R114]
    .assign attr_result = ""
    .if(dt.Name == "boolean")
      .assign attr_result = "!instance.get$cr{attribute.Name}()"
    .elif(dt.Name == "string")
      .assign attr_result = "instance.get$cr{attribute.Name}() + modifyString"
    .elif(dt.Name == "integer")
      .assign attr_result = "instance.get$cr{attribute.Name}() + 1"
    .elif(dt.Name == "real")
	  .assign attr_result = "instance.get$cr{attribute.Name}() + 1" 
	.elif(dt.Name == "unique_id")
	  .assign attr_result = "UUID.randomUUID()"
	.elif(dt.Name == "ParseStatus")
	  .assign attr_result = "Parsestatus_c.doNotParse"
	.elif(dt.Name == "Scope")
	  .assign attr_result = "Scope_c.Class"
	.elif(dt.Name == "Visibility")
	  .assign attr_result = "Visibility_c.Protected"
	.elif(dt.Name == "IFDirectionType")
	  .assign attr_result = "Ifdirectiontype_c.ServerClient"
	.elif(dt.Name == "ElementTypeConstants")
	  .assign attr_result = "Elementtypeconstants_c.DELEGATION"
	.elif(dt.Name == "instance")
	  .assign attr_result = "m_sys"
	.elif(dt.Name == "End")
	  .assign attr_result = "End_c.None"
    .end if
.end function
.function isGraphicalCheck
  .param inst_ref class
    .assign attr_isGraphical = false
    .select one ss related by class->S_SS[R2];
    .select one dom related by ss->S_DOM[R1];
    .if(not_empty dom)
      .if(dom.Name == "ooaofgraphics")
        .assign attr_isGraphical = true
      .end if
    .end if
.end function
.function generate_simple_attribute_value_tests
  .param inst_ref attr
    .select one class related by attr->O_OBJ[R102]
    /**
     *  Test modification of attribute: ${class.Name}:${attr.Name}
     */
	public void testAttributeValueModification$_{class.Name}$_{attr.Name}() throws CoreException, SecurityException, IllegalArgumentException,
			NoSuchMethodException, IllegalAccessException,
			InvocationTargetException {
		$Cr{class.Name}_c instance = null;
   .invoke igc = isGraphicalCheck(class)
   .if(igc.isGraphical)
		Ooaofgraphics[] roots = Ooaofgraphics.getInstances();
		for(Ooaofgraphics root : roots) {
			instance = $Cr{class.Name}_c.$Cr{class.Name}Instance(root);
			if(instance != null && instance.getFile() != null) {
				break;
			}
		}      
   .else
		Ooaofooa[] roots = Ooaofooa.getInstancesUnderSystem("HierarchyTestModel");
		for(Ooaofooa root : roots) {
			instance = $Cr{class.Name}_c.$Cr{class.Name}Instance(root);
     .if(attr.Name == "Visibility")
     		instance = null;
     		ModelClass_c modelClass = ModelClass_c.ModelClassInstance(root);
     		if(modelClass != null) {
				instance = PackageableElement_c.getOnePE_PEOnR8001(modelClass);
			}
	 .end if
	 .if(class.Name == "State Machine Event")
			SignalEvent_c sig = SignalEvent_c.getOneSM_SGEVTOnR526(SemEvent_c.getOneSM_SEVTOnR525(instance));
			if(instance != null && instance.getFile() != null && sig == null) {
			    break;
			}
	 .elif(class.Name == "Data Type")
			InstanceReferenceDataType_c irdt = InstanceReferenceDataType_c.getOneS_IRDTOnR17(instance);
			if(irdt != null) {
				instance = null;
				continue;
			}
     		if(instance != null && instance.getFile() != null) {
				break;
			}
     .else
     		if(instance != null && instance.getFile() != null) {
				break;
			}
	 .end if
		}
   .end if
		assertNotNull("Unable to locate test element for: ${class.Name}::${attr.Name}", instance);
    .invoke gsv = get_set_value(attr)
    .if(attr.Name == "Action_Semantics")
        performTest(instance, "setAction_semantics_internal", "${class.Name}::Action_Semantics_internal", instance.getAction_semantics_internal() + "_modified");
    .else
		performTest(instance, "set$cr{attr.Name}", "${class.Name}::${attr.Name}", ${gsv.result});
    .end if
	}
.end function
.function is_excluded
  .param inst_ref class
    .assign attr_result = false;
    .select one pkg related by class->PE_PE[R8001]->EP_PKG[R8000]
    .if(pkg.Name == "Body")
      .assign attr_result = true
    .elif(pkg.Name == "Breakpoint")
      .assign attr_result = true
    .elif(pkg.Name == "Communication and Access")
      .assign attr_result = true
    .elif(pkg.Name == "Event")
      .assign attr_result = true
    .elif(pkg.Name == "Globals")
      .assign attr_result = true
    .elif(pkg.Name == "Engine")
      .assign attr_result = true
    .elif(pkg.Name == "Local")
      .assign attr_result = true
    .elif(pkg.Name == "")
      .assign attr_result = true
    .elif(pkg.Name == "Runtime Value")
      .assign attr_result = true
    .elif(pkg.Name == "Search")
      .assign attr_result = true
    .elif(pkg.Name == "Value")
      .assign attr_result = true
    .elif(pkg.Name == "Wiring")
      .assign attr_result = true
    .elif(pkg.Name == "Participation")
      .assign attr_result = true
    .elif(pkg.Name == "Result")
      .assign attr_result = true
    .elif(pkg.Name == "Query")
      .assign attr_result = true
    .elif(pkg.Name == "Engine")
      .assign attr_result = true
    .elif(pkg.Name == "Terminal Specifications")
      .assign attr_result = true
    .elif(pkg.Name == "CT")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_DOM")
      .assign attr_result = true    
    .elif(class.Key_Lett == "CP_CP")
      .assign attr_result = true
    .elif(class.Key_Lett == "A_A")
      .assign attr_result = true
    .elif(class.Key_Lett == "A_AIA")
      .assign attr_result = true
    .elif(class.Key_Lett == "COMM_COMM")
      .assign attr_result = true
    .elif(class.Key_Lett == "COMM_CIC")
      .assign attr_result = true
    .elif(class.Key_Lett == "CP_CPINP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_DPK")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_DPIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEPIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEPK")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_FPK")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_FIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_FPIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_SS")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_SID")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_SIS")
      .assign attr_result = true
    .elif(class.Key_Lett == "EP_PIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "EP_SPKG")
      .assign attr_result = true
    .elif(class.Key_Lett == "IP_IP")
      .assign attr_result = true
    .elif(class.Key_Lett == "IP_IPINIP")
      .assign attr_result = true
    .elif(class.Key_Lett == "PA_DIC")
      .assign attr_result = true
    .elif(class.Key_Lett == "PA_SIC")
      .assign attr_result = true
    .elif(class.Key_Lett == "PA_SICP")
      .assign attr_result = true
    .elif(class.Key_Lett == "SQ_S")
      .assign attr_result = true
    .elif(class.Key_Lett == "SQ_MIS")
      .assign attr_result = true
    .elif(class.Key_Lett == "SQ_SIS")
      .assign attr_result = true
    .elif(pkg.Name == "System Level Datatypes")
      .assign attr_result = true
    .elif(class.Key_Lett == "UC_PIUC")
      .assign attr_result = true
    .elif(class.Key_Lett == "UC_UCC")
      .assign attr_result = true
    .elif(class.Key_Lett == "UC_UIU")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEDI")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEEVT")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEEDT")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEEDI")
      .assign attr_result = true
    .elif(class.Key_Lett == "S_EEM")
      .assign attr_result = true
    .elif(class.Key_Lett == "R_CONE")
      .assign attr_result = true
    .elif(class.Key_Lett == "R_COTH")
      .assign attr_result = true
    .elif(class.Key_Lett == "SQ_FPP")
      .assign attr_result = true
	.elif(class.Key_Lett == "R_COMP")
	  .assign attr_result = true
	.elif(class.Key_Lett == "STY_FS")
	  .assign attr_result = true
	.elif(class.Key_Lett == "DIM_DIA")
	  .assign attr_result = true
    .end if
    .assign exclude = "$l{class.Descrip:PEI}" == "true"
    .if(exclude)
      .assign attr_result = true
    .end if
    .assign exclude = "$l{class.Descrip:Persistent}" == "false"
    .if(exclude)
      .assign attr_result = true
    .end if
    .assign exclude = "$l{class.Descrip:persistent}" == "false"
    .if(exclude)
      .assign attr_result = true
    .end if
.end function
.function non_mod_attribute
  .param Inst_Ref attribute
    .assign attr_non_mod = false 
    .select one class related by attribute->O_OBJ[R102]
    .if((class.Name == "Package") and (attribute.Name == "Name"))
      .assign attr_non_mod = true
    .end if
    .if((class.Name == "Interface") and (attribute.Name == "Name"))
      .assign attr_non_mod = true
    .end if
    .if((class.Name == "Model Class") and (attribute.Name == "Name"))
      .assign attr_non_mod = true
    .end if
    .if((class.Name == "Component") and (attribute.Name == "Name"))
      .assign attr_non_mod = true
    .end if
.end function
.select many classes from instances of O_OBJ
.assign count = 0
.assign c = 0;
.assign test_count = 1;
.invoke gch = generate_class_header()
${gch.body}
.for each class in classes
  .invoke excluded = is_excluded(class);
  .assign exclude = excluded.result
  .if(not exclude)
    .// make sure this element is actually output
    .select any eo from instances of EO where (selected.Name == class.Name)
    .if(empty eo)
      .assign exclude = true;
    .end if
  .end if
  .if(not exclude)
    .select any ts from instances of T_TNS where (selected.Key_Lett == class.Key_Lett)
    .if(empty ts)
      .print "Did not find node for: ${class.Name} - ${class.Key_Lett}"
    .end if
    .select many attrs related by class->O_ATTR[R102];
    .for each attr in attrs
      .assign non_mod = "$l{attr.Descrip:User_Visible}" == "false"
      .if(not non_mod)
        .assign non_mod = "$l{attr.Descrip:readonly}" == "true"
      .end if
      .if(not non_mod)
        .assign non_mod = "$l{attr.Descrip:persistent}" == "false"
      .end if
      .if(not non_mod)
        .assign non_mod = "$l{attr.Descrip:Persistent}" == "false"
      .end if
      .invoke nma = non_mod_attribute(attr)
      .if(not non_mod)
        .assign non_mod = nma.non_mod
      .end if
      .select one rattr related by attr->O_RATTR[R106];
      .select one dbattr related by attr->O_BATTR[R106]->O_DBATTR[R107]
      .if(not_empty rattr)
      .elif(not_empty dbattr and attr.Name != "Action_Semantics")
      .else
        .if(not non_mod)
          .select one dt related by attr->S_DT[R114]
          .if(dt.Name != "unique_id")
            .if((attr.Name != "represents") and ((class.Name != "DiagramElement") and (attr.Name != "isVisible")))
              .invoke gavt = generate_simple_attribute_value_tests(attr)
${gavt.body}
              .assign test_count = test_count + 1
            .end if
          .end if
        .end if
      .end if
    .end for
    .assign count = count + 1
  .end if
.end for
.invoke ghm = generate_helper_methods()
${ghm.body}
}
.emit to file "src/org/xtuml/bp/model/compare/test/ModelComparisonTests.java"
.print "Class count = ${count}"
.select many nodes from instances of T_TNS
.assign count = 0
.for each node in nodes
  .assign count = count + 1
.end for
.print "Tree node count = ${count}"
.print "Generated test count = ${test_count}"