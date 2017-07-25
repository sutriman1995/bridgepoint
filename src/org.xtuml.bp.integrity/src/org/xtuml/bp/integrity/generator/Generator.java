//====================================================================
//
// File:      Generator.java
//
//====================================================================
package org.xtuml.bp.integrity.generator;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.Task;
import org.eclipse.core.filesystem.EFS;
import org.eclipse.core.filesystem.IFileStore;
import org.eclipse.core.filesystem.IFileSystem;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jface.dialogs.ProgressMonitorDialog;
import org.eclipse.jface.operation.IRunnableWithProgress;
import org.eclipse.ui.IEditorDescriptor;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.console.ConsolePlugin;
import org.eclipse.ui.console.IConsole;
import org.eclipse.ui.console.IConsoleConstants;
import org.eclipse.ui.console.IConsoleManager;
import org.eclipse.ui.console.IConsoleView;
import org.eclipse.ui.console.MessageConsole;
import org.eclipse.ui.console.MessageConsoleStream;
import org.eclipse.ui.part.FileEditorInput;
import org.xtuml.bp.core.CorePlugin;
import org.xtuml.bp.core.SystemModel_c;
import org.xtuml.bp.core.common.PersistableModelComponent;
import org.xtuml.bp.mc.AbstractActivator;
import org.xtuml.bp.mc.AbstractNature;
import org.xtuml.bp.mc.c.source.ExportBuilder;

public class Generator extends Task {
    
    public static final String INTEGRITY_LAUNCH_ID = "Check Referential Integrity.launch"; //$NON-NLS-1$
    public static final String XBUILD_LAUNCH_ID = "Integrity xtumlmc build.launch"; //$NON-NLS-1$
    public static final String EXTERNALTOOLBUILDER_FOLDER = ".externalToolBuilders"; //$NON-NLS-1$
    public static final String CORE_ICON_DIR = "icons/metadata/"; //$NON-NLS-1$
    public static final String INTEGRITY_DIR = "/tools/mc/bin/"; //$NON-NLS-1$
    public static final String INTEGRITY_EXE = "integrity"; //$NON-NLS-1$
    public static final String DOC_DIR = "doc/"; //$NON-NLS-1$
    public static final String INTEGRITY_INPUT = "a.xtuml"; //$NON-NLS-1$
    public static final String EXEFILE = ".exe"; //$NON-NLS-1$
    public static final String CONSOLE_NAME = "Console"; //$NON-NLS-1$
    private static final int SLEEPTIME = 500;
    private static final int KILLTIMEOUT = 20000;

    private static String homedir = "";
    public static MessageConsole myConsole;
    public static MessageConsoleStream msgbuf;
    public static Generator self;
    
    public Generator() {
        myConsole = findConsole(CONSOLE_NAME);
        msgbuf = myConsole.newMessageStream();
        homedir = System.getProperty("eclipse.home.location"); //$NON-NLS-1$
        homedir = homedir.replaceFirst("file:", ""); //$NON-NLS-1$
    }
    
    public static void genAll(SystemModel_c sys) {
        if (self == null) {
            self = new Generator();
        }
        
        checkReferentialIntegrity(sys);
    }
 
    /*
     * The flow of this function is: 
     * - Run the Model Compiler pre-builder 
     * - Call xtumlmc_build.exe xtumlmc_cleanse_model <model file> 
     * - Pass the stripped down model file to the integrity exe 
     */
    private static void checkReferentialIntegrity(final SystemModel_c sys) {

        final IProject project = org.xtuml.bp.io.image.generator.Generator
                .getProject(sys);
        boolean failed = false;
        
        if ( (project != null) && !failed ) {
            String projPath = project.getLocation().toOSString();
            final IPath path = new Path(projPath + File.separator
                    + DOC_DIR);
            final String destPath = path.toOSString();

            ProgressMonitorDialog pmd = new ProgressMonitorDialog(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell());
            pmd.setCancelable(true);
            pmd.create();
            IProgressMonitor monitor = pmd.getProgressMonitor();
            
            try {
                // Make sure the settings in the launch file are up to date so
                // we can invoke xtumlmc_build properly.
                AbstractNature nature = null;
                AbstractActivator activator = null;
                
                // These are used for backwards compatibility in the newer BP without a binary MC
            	final String BIN_C_MC_NATURE_ID = "org.xtuml.bp.mc.c.binary.MCNature"; //NON-NLS-1
            	final String BIN_C_MC_NATURE_ID_OLD = "com.mentor.nucleus.bp.mc.c.binary.MCNature"; //NON-NLS-1

                if ( project.hasNature(BIN_C_MC_NATURE_ID) || project.hasNature(BIN_C_MC_NATURE_ID_OLD) ) {
                    nature = org.xtuml.bp.mc.c.source.MCNature.getDefault();
                    activator = org.xtuml.bp.mc.c.source.Activator.getDefault();
                }
                else if ( project.hasNature(org.xtuml.bp.mc.c.source.MCNature.MC_NATURE_ID) || project.hasNature(org.xtuml.bp.mc.c.source.MCNature.MC_NATURE_ID_OLD) ) {
                    nature = org.xtuml.bp.mc.c.source.MCNature.getDefault();
                    activator = org.xtuml.bp.mc.c.source.Activator.getDefault();
                }
                else if ( project.hasNature(org.xtuml.bp.mc.cpp.source.MCNature.MC_NATURE_ID) || project.hasNature(org.xtuml.bp.mc.cpp.source.MCNature.MC_NATURE_ID_OLD) ) {
                    nature = org.xtuml.bp.mc.cpp.source.MCNature.getDefault();
                    activator = org.xtuml.bp.mc.cpp.source.Activator.getDefault();
                }
                else if ( project.hasNature(org.xtuml.bp.mc.systemc.source.MCNature.MC_NATURE_ID) || project.hasNature(org.xtuml.bp.mc.systemc.source.MCNature.MC_NATURE_ID_OLD) ) {
                    nature = org.xtuml.bp.mc.systemc.source.MCNature.getDefault();
                    activator = org.xtuml.bp.mc.systemc.source.Activator.getDefault();
                }
                org.xtuml.bp.mc.MCBuilderArgumentHandler argHandlerAbstract = new org.xtuml.bp.mc.MCBuilderArgumentHandler(
                        project, activator, nature);
                argHandlerAbstract.setArguments(nature.getBuilderID());                

                // Next proceed with actually running integrity on the model
                IWorkbenchPage page = PlatformUI.getWorkbench()
                        .getActiveWorkbenchWindow().getActivePage();
                String id = IConsoleConstants.ID_CONSOLE_VIEW;
                IConsoleView view = (IConsoleView) page.showView(id);
                view.display(myConsole);

                pmd.run(true, true, new IRunnableWithProgress() {

                    public void run(IProgressMonitor monitor)
                            throws InvocationTargetException,
                            InterruptedException {

                        int steps = 8;
                        int curStep = 1;
                        List<SystemModel_c> exportedSystems = new ArrayList<SystemModel_c>();

                        monitor.beginTask("Check Referential Integrity", steps);

                        if (!path.toFile().exists()) {
                            path.toFile().mkdir();
                        }

                        while (curStep <= steps) {
                            if (monitor.isCanceled()) {
                                InterruptedException ie = new InterruptedException("User cancelled the operation");
                                throw ie;
                            }

                            try {
                                switch (curStep) {
                                case 1:
                                    monitor.subTask("Cleaning");
                                    cleanup(destPath);
                                    monitor.worked(1);
                                    break;
                                case 2:
                                    monitor.subTask("Loading model");
                                    PersistableModelComponent pmc = sys.getPersistableComponent();
                                    pmc.loadComponentAndChildren(new NullProgressMonitor());
                                    monitor.worked(1);
                                    break;
                                case 3:
                                    monitor.subTask("Gathering model information");
                                    ExportBuilder eb = new ExportBuilder();
                                    exportedSystems = eb.exportSystem(sys, destPath, new NullProgressMonitor());
                                    monitor.worked(1);
                                    break;
                                case 4:
                                    monitor.subTask("SKIPPING Generating images");
                                    monitor.worked(1);
                                    break;
                                case 5:
                                    monitor.subTask("Prepping model for document generation");
                                    runXbuild(project, destPath);
                                    monitor.worked(1);
                                    break;
                                case 6:
                                    monitor.subTask("Processing model");
                                    runIntegrity(project, destPath);
                                    monitor.worked(1);
                                    break;
                                case 7:
                                    monitor.subTask("not Generating display data");
                                    monitor.worked(1);
                                    break;
                                case 8:
                                    monitor.subTask("Refreshing");
                                    project.refreshLocal(IResource.DEPTH_INFINITE, null);
                                    monitor.worked(1);
                                    break;
                                }
                            } catch (Throwable e) {
                            	RuntimeException err = new RuntimeException(e.getMessage());
                                throw err;
                            } 
                            curStep++;
                        }
                    }
                });

                openOutput(project);
            } catch (Throwable e) {
                String errMsg = e.getMessage();
                if ( (errMsg == null) || errMsg.isEmpty() ) {
                    Throwable cause = e.getCause();
                    if ( cause != null ) {
                        errMsg = cause.getMessage();
                    } 
                    
                    if ((cause == null) || (errMsg == null)) {
                        errMsg = "";
                    }
                }
                logMsg("Error.  Check Referential Integrity failed: " + errMsg);
                CorePlugin.logError("Error.  Check Referential Integrity failed: " + errMsg, e);
                failed = true;
            } finally {
                if (failed) {
                    try {
                        cleanup(destPath);
                        project.refreshLocal(IResource.DEPTH_INFINITE, null);
                    } catch (CoreException ce) {
                        String errMsg = ce.getMessage();
                        if ( (errMsg == null) || errMsg.isEmpty() ) {
                            errMsg = "CoreException";
                        }
                        logMsg("Error.  Check Referential Integrity failed during cleanup: " + errMsg);
                        CorePlugin.logError("Error.  Check Referential Integrity failed during cleanup: " + errMsg, ce);
                    }
                } else {
                    logMsg("Check Referential Integrity finished successfully.");
                }
                monitor.done();
            }
        }
    }
 
    private static void cleanup(String workingDir) 
        throws CoreException
    {
        /* NOTE: At initial implementation we have decide to leave the
         * generated data alone so we don't delete any potential user 
         * created data.
         * 
        File workDir = new File(workingDir);
        File[] files = workDir.listFiles();
        for (File file: files) {
            if ( file.isDirectory() ) {
                cleanup(file.toString());
                file.delete();
            } else {
                file.delete();
            }
        }*/
    }

    private static void runXbuild(IProject project, String workingDir) 
        throws IOException, RuntimeException, CoreException, InterruptedException
    {
        // Call xtumlmc_build.exe xtumlmc_cleanse_model <infile> <outfile>
        String app = AbstractNature.getLaunchAttribute(project, 
                    org.xtuml.bp.mc.AbstractNature.LAUNCH_ATTR_TOOL_LOCATION);
        String args = "xtumlmc_cleanse_model";  //$NON-NLS-1$
        String inputfile = project.getName() + ".sql"; //$NON-NLS-1$
        String middlefile = "z.xtuml";  //$NON-NLS-1$
        String outputfile = INTEGRITY_INPUT;
        File output = new File(workingDir + outputfile);
        File middle = new File(workingDir + middlefile);
        File sqlfile = new File(workingDir + inputfile);

        if ( middle.exists() ) {
            middle.delete();
        }
        if ( output.exists() ) {
            output.delete();
        }
        
        ProcessBuilder pb = new ProcessBuilder(app, args, inputfile, middlefile);
        pb.directory(new File(workingDir));
        Process process = pb.start();
        process.waitFor();
        
        project.refreshLocal(IResource.DEPTH_INFINITE, null);
        if ( !middle.exists() ) {
            RuntimeException re = new RuntimeException("Expected output file doesn't exist: " +
                    middle.toString());
            throw re;
        }

        // Call xtumlmc_build.exe ReplaceUUIDWithLong <infile> <outfile>
        args = "ReplaceUUIDWithLong";  //$NON-NLS-1$

        pb = new ProcessBuilder(app, args, middlefile, outputfile);
        pb.directory(new File(workingDir));
        process = pb.start();
        process.waitFor();
        
        sqlfile.delete();
        middle.delete();
        project.refreshLocal(IResource.DEPTH_INFINITE, null);
        if ( !output.exists() ) {
            RuntimeException re = new RuntimeException("Expected output file doesn't exist: " +
                    output.toString());
            throw re;
        }
    }
    
    private static void runIntegrity(IProject project, String workingDir) 
        throws IOException, RuntimeException, CoreException, InterruptedException 
    {
        // Call integrity.exe 
        String app = homedir + INTEGRITY_DIR + INTEGRITY_EXE;
        String outputfile = DOC_XML;
        File output = new File(workingDir + outputfile);
        File input = new File(workingDir + INTEGRITY_INPUT);

        if (output.exists()) {
            output.delete();
        }
        
        ProcessBuilder pb = new ProcessBuilder(app); 
        pb.directory(new File(workingDir));
        Process process = pb.start();
        int exitVal = doWaitFor(process, null);
        
        input.delete();
        project.refreshLocal(IResource.DEPTH_INFINITE, null);
        if ( exitVal == -1 ) {
            RuntimeException re = new RuntimeException("check integrity subprocess failed: " +
                    output.toString());
            throw re;            
        } else if ( !output.exists() ) {
            RuntimeException re = new RuntimeException("Expected output file doesn't exist: " +
                    output.toString());
            throw re;
        }
    }

    private static MessageConsole findConsole(String name) {
        ConsolePlugin plugin = ConsolePlugin.getDefault();
        IConsoleManager conMan = plugin.getConsoleManager();
        IConsole[] existing = conMan.getConsoles();
        for (int i = 0; i < existing.length; i++) {
            if (name.equals(existing[i].getName())) {
                return (MessageConsole) existing[i];
            }
        }
        // no console found, so create a new one
        MessageConsole myConsole = new MessageConsole(name, null);
        conMan.addConsoles(new IConsole[] { myConsole });
        return myConsole;
    }

    private static void logMsg(String msg) {
        try {
            msgbuf.println(msg);
            msgbuf.flush();
            while(PlatformUI.getWorkbench().getDisplay().readAndDispatch());
        } catch (IOException ioe) {
        }
    }

    private static int doWaitFor(Process p, File output) {

        int exitValue = -1; // returned to caller when p is finished
        int totalTime = 0;

        try {
            BufferedReader is = new BufferedReader(new InputStreamReader(p.getInputStream()));
            DataOutputStream dos = null;
            
            if (output != null) {
                dos = new DataOutputStream(
                    new BufferedOutputStream(new FileOutputStream(output)));
            }
            String line;

            boolean finished = false; // Set to true when p is finished

            while (!finished) {
                try {
                    while ((line = is.readLine()) != null) {
                        if ( dos != null) {
                            dos.writeBytes(line);
                            dos.write('\n');
                        }
                    }

                    // Ask the process for its exitValue. If the process
                    // is not finished, an IllegalThreadStateException
                    // is thrown. If it is finished, we fall through and
                    // the variable finished is set to true.
                    exitValue = p.exitValue();
                    finished = true;
                } catch (IllegalThreadStateException e) {
                    // Process is not finished yet;
                    // Sleep a little to save on CPU cycles
                    Thread.sleep(SLEEPTIME);
                    totalTime = totalTime + SLEEPTIME;
                    
                    if (totalTime > KILLTIMEOUT) {
                        finished = true;
                        p.destroy();
                    }
                }
                if (dos != null) {
                    dos.flush();
                    dos.close();
                }
            }
        } catch (Exception e) {
            // unexpected exception! print it out for debugging...
            System.err.println("doWaitFor(): unexpected exception - " + e.getMessage());
        }

        return exitValue;
    }

    public static Path findProgramInPath(String desiredProgram) {
        ProcessBuilder pb = new ProcessBuilder(isWindows() ? "where" : "which", desiredProgram);
        Path foundProgram = null;
        try {
            Process proc = pb.start();
            int errCode = proc.waitFor();
            if (errCode == 0) {
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()))) {
                	// Found it!
                    foundProgram = new Path(reader.readLine());
                }
            } else {
            	System.err.println(desiredProgram + " not in PATH");
            }
        } catch (IOException ex) {
        	System.err.println("Something went wrong while searching for " + desiredProgram);
        } catch (InterruptedException ex) {
        	System.err.println("Something went wrong while searching for " + desiredProgram);
        }
        return foundProgram;
    }
    
    private static boolean isWindows() {
        return System.getProperty("os.name").toLowerCase().contains("windows");
    }
    
}
