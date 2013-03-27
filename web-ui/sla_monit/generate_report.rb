module Uhuru::BoshCommander::SlaMonit
  class Data

    def initialize()
      #connect to database
    end

    def grab_data()
    end

  end

  class ReportGenerator

    def initialize(resolution_unit, sample_count, resolution)
      @resolution_unit = resolution_unit
      @sampleCount = sample_count
      @resolution = resolution
    end

    def compile_deployment
      data = Data.new.grab_data

      iterator = 0
      current_time = DateTime.now
      t0  = DateTime.now
      t1 = DateTime.now
      utc_offset = 0
      t0_str = t0.to_s

      sql VarChar(1000)
      template varchar(1000)

      x_overall_status = ''
      x_push_status = ''
      x_http_status = ''
      x_latency = ''
      x_duration = ''
      #
      #set @currentTime = dateadd(HOUR, -1, getutcdate())
      #
      #if @resolutionUnit = 'min' set @currentTime = dateadd(minute,datediff(minute,0,@currentTime),0);
      #if @resolutionUnit = 'hour'set @currentTime = dateadd(hour,datediff(hour,0,@currentTime),0);
      #if @resolutionUnit = 'day' set @currentTime = dateadd(day,datediff(day,0,@currentTime),0);
      #if @resolutionUnit = 'week'set @currentTime = dateadd(week,datediff(week,0,@currentTime),0);
      #if @resolutionUnit = 'month' set @currentTime = dateadd(month,datediff(month,0,@currentTime),0);
      #
      #CREATE TABLE #DashBoard(
      #Info varchar(50),
      #     Framework varchar(50),
      #               [Service] varchar(50),
      #    [Uptime] varchar(50))
      #
      #insert into #DashBoard (Info, Framework, [Service])
      #SELECT 'Status', 'All', 'All' UNION ALL
      #SELECT 'Push Outcome', 'All', 'All' UNION ALL
      #SELECT 'App Online', 'All', 'All' UNION ALL
      #SELECT 'Push Duration', 'All', 'All' UNION ALL
      #SELECT 'Latency', 'All', 'All'
      #
      #DECLARE @service VARCHAR(50)
      #DECLARE @framework VARCHAR(50)
      #
      #DECLARE
      #db_cursor
      #CURSOR FOR
      #SELECT
      #[Framework],
      #    [Service]
      #FROM
      #TestAppDefinitions
      #
      #OPEN db_cursor
      #FETCH NEXT FROM db_cursor INTO @framework, @service
      #
      #WHILE @@FETCH_STATUS = 0
      #BEGIN
      #  insert into #DashBoard (Info, Framework, [Service])
      #  SELECT 'Status', @framework, @service UNION ALL
      #  SELECT 'Push Outcome', @framework, @service UNION ALL
      #  SELECT 'App Online', @framework, @service UNION ALL
      #  SELECT 'Push Duration', @framework, @service UNION ALL
      #  SELECT 'Latency', @framework, @service
      #
      #  FETCH NEXT FROM db_cursor INTO @framework, @service
      #  END
      #
      #    CLOSE db_cursor
      #    DEALLOCATE db_cursor
      #
      #    set @iterator = @sampleCount
      #
      #    while @iterator > 0
      #      begin
      #        if @resolutionUnit = 'min' set @t0 = dateadd(minute, @resolution * -1 * @iterator, @currentTime)
      #        if @resolutionUnit = 'hour' set @t0 = dateadd(hour, @resolution * -1 * @iterator, @currentTime)
      #        if @resolutionUnit = 'day' set @t0 = dateadd(day, @resolution * -1 * @iterator, @currentTime)
      #        if @resolutionUnit = 'week' set @t0 = dateadd(week, @resolution * -1 * @iterator, @currentTime)
      #        if @resolutionUnit = 'month' set @t0 = dateadd(month, @resolution * -1 * @iterator, @currentTime)
      #
      #        if @resolutionUnit = 'min' set @t1 = dateadd(minute, @resolution, @t0)
      #        if @resolutionUnit = 'hour' set @t1 = dateadd(hour, @resolution, @t0)
      #        if @resolutionUnit = 'day' set @t1 = dateadd(day, @resolution, @t0)
      #        if @resolutionUnit = 'week' set @t1 = dateadd(week, @resolution, @t0)
      #        if @resolutionUnit = 'month' set @t1 = dateadd(month, @resolution, @t0)
      #
      #        set @t0str = CAST(@t0 as varchar(50))
      #
      #        EXEC xp_sprintf @SQL output, 'ALTER TABLE #dashboard ADD [%s] VARCHAR(50)', @t0str
      #        exec(@sql)
      #
      #
      #        select
      #        @xPushStatus	= CAST(	AVG(CAST(xPushStatus as float))						as VARCHAR(1000)),
      #            @xHttpStatus	= CAST(	AVG(CAST(xHttpStatus as float))						as VARCHAR(1000)),
      #            @xOverallStatus = CAST(	AVG(CAST(xPushStatus * xHttpStatus as float))		as VARCHAR(1000)),
      #            @xDuration		= CAST(	AVG(CAST(xAvgPush as float))						as VARCHAR(1000)),
      #            @xLatency		= CAST(	AVG(CAST(xAvgLatency as float))						as VARCHAR(1000))
      #        from
      #        Applications
      #        where
      #        xUTCTime < @t1 and xUTCTime >= @t0 and xProcessed = 1
      #
      #        set @template = 'update #dashboard set [%s] =''%s'' where [info]=''%s'' and [service]=''%s'' and [framework]=''%s'''
      #
      #        if @xOverallStatus <> '' begin EXEC xp_sprintf @sql output, @template, @t0str, @xOverallStatus, 'Status', 'All', 'All'; exec(@sql); end
      #        if @xPushStatus <> '' begin EXEC xp_sprintf @sql output, @template, @t0str, @xPushStatus, 'Push Outcome', 'All', 'All'; exec(@sql); end
      #        if @xHttpStatus <> '' begin EXEC xp_sprintf @sql output, @template, @t0str, @xHttpStatus, 'App Online', 'All', 'All'; exec(@sql); end
      #        if @xDuration <> '' begin EXEC xp_sprintf @sql output, @template, @t0str, @xDuration, 'Push Duration', 'All', 'All'; exec(@sql); end
      #        if @xLatency <> '' begin EXEC xp_sprintf @sql output, @template, @t0str, @xLatency, 'Latency', 'All', 'All'; exec(@sql); end
      #
      #
      #
      #        DECLARE db_cursor CURSOR FOR
      #        select
      #        CAST(	AVG(CAST(xPushStatus as float))							as VARCHAR(1000)),
      #            CAST(	AVG(CAST(xHttpStatus as float))							as VARCHAR(1000)),
      #            CAST(	AVG(CAST(xPushStatus * xHttpStatus as float))			as VARCHAR(1000)),
      #            CAST(	AVG(CAST(xAvgPush as float))							as VARCHAR(1000)),
      #            CAST(	AVG(CAST(xAvgLatency as float))							as VARCHAR(1000)),
      #            xFramework,
      #                xService
      #        from
      #        Applications
      #        where
      #        xUTCTime < @t1 and xUTCTime >= @t0 and xProcessed = 1
      #        group by
      #        xFramework, xService
      #
      #
      #
      #        OPEN db_cursor
      #        FETCH NEXT FROM db_cursor INTO @xPushStatus, @xHttpStatus, @xOverallStatus, @xDuration, @xLatency, @framework, @service
      #
      #        WHILE @@FETCH_STATUS = 0
      #        BEGIN
      #
      #          set @template = 'update #dashboard set [%s] =''%s'' where [info]=''%s'' and [service]=''%s'' and [framework]=''%s'''
      #
      #          EXEC xp_sprintf @sql output, @template, @t0str, @xOverallStatus, 'Status', @service, @framework; exec(@sql)
      #          EXEC xp_sprintf @sql output, @template, @t0str, @xPushStatus, 'Push Outcome', @service, @framework; exec(@sql)
      #          EXEC xp_sprintf @sql output, @template, @t0str, @xHttpStatus, 'App Online', @service, @framework; exec(@sql)
      #          EXEC xp_sprintf @sql output, @template, @t0str, @xDuration, 'Push Duration', @service, @framework; exec(@sql)
      #          EXEC xp_sprintf @sql output, @template, @t0str, @xLatency, 'Latency', @service, @framework; exec(@sql)
      #
      #          FETCH NEXT FROM db_cursor INTO @xPushStatus, @xHttpStatus, @xOverallStatus, @xDuration, @xLatency, @framework, @service
      #          END
      #
      #            CLOSE db_cursor
      #            DEALLOCATE db_cursor
      #
      #            set @iterator = @iterator - 1;
      #            end
      #
      #
      #            if @resolutionUnit = 'min' set @t0 = dateadd(minute, @resolution * -1 * @sampleCount, @currentTime)
      #            if @resolutionUnit = 'hour' set @t0 = dateadd(hour, @resolution * -1 * @sampleCount, @currentTime)
      #            if @resolutionUnit = 'day' set @t0 = dateadd(day, @resolution * -1 * @sampleCount, @currentTime)
      #            if @resolutionUnit = 'week' set @t0 = dateadd(week, @resolution * -1 * @sampleCount, @currentTime)
      #            if @resolutionUnit = 'month' set @t0 = dateadd(month, @resolution * -1 * @sampleCount, @currentTime)
      #
      #            select * into #slaTable from(
      #            select
      #            'All' as [Framework],
      #                     'All' as [Service],
      #                              100 * (SUM(xHttpStatus * xPushStatus) / CAST(COUNT(1) as float)) as Uptime
      #            from
      #            Applications
      #            where
      #            xUTCTime < @t1 and xUTCTime >= @t0 and xProcessed = 1
      #
      #            union all
      #
      #            select
      #            xFramework as [Framework],
      #                          xService as [Service],
      #                                      100 * (SUM(xHttpStatus * xPushStatus) / CAST(COUNT(1) as float)) as Uptime
      #            from
      #            Applications
      #            where
      #            xUTCTime < @t1 and xUTCTime >= @t0 and not xFramework is null and not [xService] is null and xProcessed = 1
      #            group by
      #            xFramework, [xService]) slaTable
      #
      #            update
      #                          #DashBoard
      #            set
      #                          #DashBoard.Uptime = #slaTable.Uptime
      #            from
      #                          #DashBoard
      #            inner join
      #                          #slaTable on (#slaTable.Framework = #DashBoard.Framework and #slaTable.[Service] = #DashBoard.[Service])
      #
      #            select * from #DashBoard
      #            drop table #DashBoard
      #            drop table #slaTable
    end

    def render_html(out_file)
    end

  end
end