/*
 * Copyright (C) 2016 VNG/KING
 * 
 * This file is part of Imvertor.
 *
 * Imvertor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Imvertor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Imvertor.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package nl.imvertor.ConfigCompiler;

import java.util.Iterator;

import org.apache.log4j.Logger;

import nl.imvertor.common.Step;
import nl.imvertor.common.Transformer;
import nl.imvertor.common.file.AnyFolder;
import nl.imvertor.common.file.XmlFile;
import nl.imvertor.common.file.XslFile;
import nl.imvertor.common.file.ZipFile;
import nl.imvertor.common.xsl.extensions.counting.AddNamedCount;
import nl.imvertor.common.xsl.extensions.counting.GetNamedCount;
import nl.imvertor.common.xsl.extensions.counting.SetNamedCount;

/**
 * create a configuration for the current owner, tagset, metamodel and schemas
 * 
 * @author arjan
 *
 */
public class ConfigCompiler  extends Step {

	protected static final Logger logger = Logger.getLogger(ConfigCompiler.class);
	
	public static final String STEP_NAME = "ConfigCompiler";
	public static final String VC_IDENTIFIER = "$Id: ReleaseCompiler.java 7473 2016-03-22 07:30:03Z arjan $";
	
	/**
	 *  run the step
	 */
	public boolean run() throws Exception{
		
		// set up the configuration for this step
		configurator.setActiveStepName(STEP_NAME);
		prepare();
		runner.info(logger,"Compiling the configuration");
			
		Transformer transformer = new Transformer();
		
		 // transform 
		boolean succeeds = true;
		
		succeeds = succeeds ? transformer.transformStep("system/cur-imvertor-filepath", "properties/WORK_CONFIG_FILE", "properties/IMVERTOR_CONFIG_XSLPATH") : false ;
			
		configurator.setStepDone(STEP_NAME);
		 
		// save any changes to the work configuration for report and future steps
	    configurator.save();
	    
	    report();
	    
	    return runner.succeeds();

	}
	
}