package com.red5pro.awsdeployer;

import org.apache.commons.chain.Context;
import org.apache.commons.chain.impl.ContextBase;

import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.BasicAWSCredentials;
import com.red5pro.awsdeployer.commands.IPReservationCommand;
import com.red5pro.awsdeployer.commands.VPCCreationCommand;
import com.red5pro.awsdeployer.model.Configuration;

/**
 * Hello world!
 *
 */
public class AutoDeployer 
{
    public static void main( String[] args )
    {
    	Configuration conf = new Configuration();
    	AWSCredentials creds = new BasicAWSCredentials(conf.getAwsAccessKey(), conf.getAwsAccessSecret());
    	
    	Context ctx = new ContextBase();
    	ctx.put("configuration", conf);
    	ctx.put("credentials", creds);    	
    	
    	try 
    	{
    		
		}
    	catch (Exception e) 
    	{
			e.printStackTrace();
		}
    }
}
