{/* Latest Notifications Feed - Always shown */}
        <motion.div variants={item} className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-neutral-ink-800" style={{ fontSize: '1.125rem', letterSpacing: '-0.01em' }}>{t('latestNotifications')}</h3>
            <motion.div
              animate={{ scale: [1, 1.1, 1] }}
              transition={{ duration: 2, repeat: Infinity, repeatDelay: 3 }}
              className="w-2 h-2 rounded-full bg-accent-lime-500 shadow-lg shadow-accent-lime-500/50"
            ></motion.div>
          </div>
          
          <div className="space-y-2.5">
            {feedItems.map((feedItem, index) => (
              <motion.div
                key={feedItem.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.6 + index * 0.1, duration: 0.5 }}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="cursor-pointer"
              >
                <div className={`relative overflow-hidden rounded-2xl bg-gradient-to-br from-white to-surface-warm-50 border border-neutral-line-200/40 hover:border-neutral-line-200 transition-all duration-300 group
                  ${feedItem.type === 'maintenance' 
                    ? 'shadow-[0_2px_8px_-2px_rgba(255,152,0,0.08),0_4px_16px_-4px_rgba(255,152,0,0.06)] hover:shadow-[0_8px_24px_-4px_rgba(255,152,0,0.16),0_12px_32px_-8px_rgba(255,152,0,0.12)]' 
                    : feedItem.type === 'document'
                    ? 'shadow-[0_2px_8px_-2px_rgba(76,175,71,0.08),0_4px_16px_-4px_rgba(76,175,71,0.06)] hover:shadow-[0_8px_24px_-4px_rgba(76,175,71,0.16),0_12px_32px_-8px_rgba(76,175,71,0.12)]'
                    : 'shadow-[0_2px_8px_-2px_rgba(33,150,243,0.08),0_4px_16px_-4px_rgba(33,150,243,0.06)] hover:shadow-[0_8px_24px_-4px_rgba(33,150,243,0.16),0_12px_32px_-8px_rgba(33,150,243,0.12)]'
                  }`}
                >
                  {/* Premium Colored Accent Border */}
                  <div className={`absolute left-0 top-0 bottom-0 w-1 ${
                    feedItem.type === 'maintenance'
                      ? 'bg-gradient-to-b from-warning via-warning to-warning/60'
                      : feedItem.type === 'document'
                      ? 'bg-gradient-to-b from-brand-sage-500 via-brand-sage-500 to-brand-sage-400'
                      : 'bg-gradient-to-b from-info via-info to-info/60'
                  }`}></div>
                  
                  {/* Subtle Glow Effect */}
                  <div className={`absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ${
                    feedItem.type === 'maintenance'
                      ? 'bg-gradient-to-r from-warning/5 to-transparent'
                      : feedItem.type === 'document'
                      ? 'bg-gradient-to-r from-brand-sage-500/5 to-transparent'
                      : 'bg-gradient-to-r from-info/5 to-transparent'
                  }`}></div>
                  
                  <div className="relative p-3.5 pl-4">
                    <div className="flex gap-3.5 items-start">
                      {/* Premium Icon Container */}
                      <motion.div 
                        whileHover={{ scale: 1.1, rotate: [0, -5, 5, 0] }}
                        transition={{ duration: 0.4 }}
                        className={`relative flex-shrink-0 w-11 h-11 rounded-xl flex items-center justify-center backdrop-blur-sm ${
                          feedItem.type === 'maintenance'
                            ? 'bg-gradient-to-br from-warning/20 via-warning/15 to-warning/5 shadow-lg shadow-warning/20'
                            : feedItem.type === 'document'
                            ? 'bg-gradient-to-br from-brand-sage-100 via-brand-sage-50 to-white shadow-lg shadow-brand-sage-500/20'
                            : 'bg-gradient-to-br from-info/20 via-info/15 to-info/5 shadow-lg shadow-info/20'
                        }`}
                      >
                        {/* Icon Glow */}
                        <div className={`absolute inset-0 rounded-xl blur-md opacity-50 ${
                          feedItem.type === 'maintenance'
                            ? 'bg-warning/30'
                            : feedItem.type === 'document'
                            ? 'bg-brand-sage-500/30'
                            : 'bg-info/30'
                        }`}></div>
                        
                        {feedItem.type === 'maintenance' ? (
                          <Wrench className={`relative z-10 w-5 h-5 ${feedItem.priority === 'high' ? 'text-warning' : 'text-neutral-ink-600'}`} />
                        ) : feedItem.type === 'document' ? (
                          <FileText className="relative z-10 w-5 h-5 text-brand-sage-600" />
                        ) : (
                          <AlertCircle className="relative z-10 w-5 h-5 text-info" />
                        )}
                      </motion.div>
                      
                      {/* Content */}
                      <div className="flex-1 min-w-0 pt-0.5">
                        <h4 className="mb-1 font-semibold text-neutral-ink-800 group-hover:text-brand-sage-600 transition-colors leading-tight">{feedItem.title}</h4>
                        <p className="text-xs text-neutral-ink-500 mb-1.5 line-clamp-1 leading-relaxed">
                          {feedItem.description}
                        </p>
                        <div className="flex items-center gap-2">
                          <div className="flex-shrink-0 w-1 h-1 rounded-full bg-neutral-ink-300"></div>
                          <p className="text-xs text-neutral-ink-400 font-medium">{feedItem.time}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>